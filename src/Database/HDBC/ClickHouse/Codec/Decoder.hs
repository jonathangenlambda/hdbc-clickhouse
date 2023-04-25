{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ViewPatterns #-}

module Database.HDBC.ClickHouse.Codec.Decoder where

import Control.Exception (throwIO)
import Data.Array.ST (MArray, STUArray, newArray, readArray)
import Data.Array.Unsafe (castSTUArray)
import Data.Bits (Bits, shiftL, (.&.), (.|.))
import Data.Int (Int16, Int32, Int64, Int8)
import Data.List ((\\))
import Data.Time (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import Data.Word (Word16, Word32, Word64, Word8)
import Database.HDBC.ClickHouse.Exception (ClickHouseException (..), unexpectedResponse)
import GHC.ST (ST, runST)
import Network.Socket (Socket)
import Network.Socket.ByteString (recv)

import qualified Codec.Binary.UTF8.String as C
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as B8
import Data.Time.Clock.System

readString :: Socket -> IO String
readString sock = do
    size <- readNum sock
    bs <-
        if size == 0
            then return B.empty
            else recv sock $ fromIntegral size
    return $ C.decodeString $ B8.unpack bs

readFixedString :: Socket -> Int -> IO String
readFixedString sock size = do
    bs <-
        if size == 0
            then return B.empty
            else recv sock size
    return $ C.decodeString $ B8.unpack $ B.map replaceNULToEmptyChar bs
  where
    replaceNULToEmptyChar 0 = 32
    replaceNULToEmptyChar x = x

readNum :: Socket -> IO Word64
readNum sock = readNum' sock 0 0
  where
    readNum' :: Socket -> Word64 -> Int -> IO Word64
    readNum' sock n s = do
        bs <- recv sock 1
        case (B.unpack bs) of
            [b]
                | b < 0x80 -> return $ fromIntegral (n .|. (fromIntegral b) `shiftL` s)
                | otherwise -> readNum' sock (fromIntegral (n .|. ((fromIntegral b) .&. 0x7f) `shiftL` s)) (s + 7)
            xs -> throwIO $ unexpectedResponse "Number" xs

readBool :: Socket -> IO Bool
readBool sock = do
    bs <- recv sock 1
    case (B.unpack bs) of
        [1] -> return True
        [0] -> return False
        xs -> throwIO $ unexpectedResponse "Bool" xs

readInt8 :: Socket -> IO Int8
readInt8 sock = do
    bs <- recv sock 1
    case (B.unpack bs) of
        [n] -> return $ fromIntegral n
        xs -> throwIO $ unexpectedResponse "Int8" xs

readInt16 :: Socket -> IO Int16
readInt16 sock = readFixedNum sock 0 2

readInt32 :: Socket -> IO Int32
readInt32 sock = readFixedNum sock 0 4

readInt64 :: Socket -> IO Int64
readInt64 sock = readFixedNum sock 0 8

readWord8 :: Socket -> IO Word8
readWord8 sock = do
    bs <- recv sock 1
    case (B.unpack bs) of
        [n] -> return n
        xs -> throwIO $ unexpectedResponse "Word8" xs

readWord16 :: Socket -> IO Word16
readWord16 sock = readFixedNum sock 0 2

readWord32 :: Socket -> IO Word32
readWord32 sock = readFixedNum sock 0 4

readWord64 :: Socket -> IO Word64
readWord64 sock = readFixedNum sock 0 8

readFixedNum :: (Num a, Bits a) => Socket -> a -> Int -> IO a
readFixedNum sock zero size = do
    bs <- recv sock size
    let (i, _) = B.foldl (\(n, s) b -> (n .|. ((fromIntegral b) `shiftL` s), s + 8)) (zero, 0) bs
    return i

readFloat32 :: Socket -> IO Float
readFloat32 sock = do
    w32 <- readWord32 sock
    return $ wordToFloat w32

readFloat64 :: Socket -> IO Double
readFloat64 sock = do
    w64 <- readWord64 sock
    return $ wordToDouble w64

-- https://stackoverflow.com/a/7002812
wordToFloat :: Word32 -> Float
wordToFloat x = runST (cast x)

wordToDouble :: Word64 -> Double
wordToDouble x = runST (cast x)

{-# INLINE cast #-}
cast ::
    ( MArray (STUArray s) a (ST s)
    , MArray (STUArray s) b (ST s)
    ) =>
    a ->
    ST s b
cast x = newArray (0 :: Int, 0) x >>= castSTUArray >>= flip readArray 0

readDate :: Socket -> IO UTCTime
readDate sock = do
    sec <- readInt16 sock
    return $ posixSecondsToUTCTime $ (fromIntegral sec) * 24 * 3600

readDateTime :: Socket -> IO UTCTime
readDateTime sock = do
    sec <- readInt32 sock
    return $ posixSecondsToUTCTime $ fromIntegral sec

readDateTime64 :: Socket -> IO UTCTime
readDateTime64 sock = mkUtcTime <$> readInt64 sock
  where
    mkUtcTime :: Int64 -> UTCTime
    mkUtcTime nanosEpoch = systemToUTCTime $ MkSystemTime seconds nanos
      where
        (seconds, fromIntegral -> nanos) = nanosEpoch `divMod` (10 ^ 9)

readException :: Socket -> IO ClickHouseException
readException sock = do
    code <- readInt32 sock
    name <- readString sock
    message <- readString sock
    stackTrace <- readString sock
    hasNested <- readBool sock
    nested <-
        if hasNested
            then fmap Just (readException sock)
            else return Nothing
    return
        ServerException
            { code = fromIntegral code
            , name = name
            , message = message \\ (name ++ ": ")
            , stackTrace = stackTrace
            , nested = nested
            }

readAll :: Socket -> IO B.ByteString
readAll sock =
    readAll' sock B.empty
  where
    readAll' sock bs = do
        r <- recv sock 1024
        if (B.length r == 0 || B.last r == 4)
            then return $ bs `B.append` r
            else readAll' sock $ bs `B.append` r
