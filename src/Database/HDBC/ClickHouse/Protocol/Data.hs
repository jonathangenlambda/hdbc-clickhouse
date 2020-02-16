module Database.HDBC.ClickHouse.Protocol.Data where

import Data.Time
import Data.Word
import Database.HDBC.SqlValue
import Network.Socket (Socket)

import qualified Data.ByteString as B
import qualified Database.HDBC.ClickHouse.Protocol.Codec.Decoder as D

data Column = StringColumn {
    columnName :: String
} | Int8Column {
    columnName :: String
} | Int16Column {
    columnName :: String
} | Int32Column {
    columnName :: String
} | Int64Column {
    columnName :: String
} | UInt8Column {
    columnName :: String
} | UInt16Column {
    columnName :: String
} | UInt32Column {
    columnName :: String
} | UInt64Column {
    columnName :: String
} | Float32Column {
    columnName :: String
} | Float64Column {
    columnName :: String
} | DateColumn {
    columnName :: String
} | DateTimeColumn {
    columnName :: String
} deriving Show

createColumn :: String -> String -> Column
createColumn name "String"   = StringColumn { columnName = name }
createColumn name "Int8"     = Int8Column { columnName = name }
createColumn name "Int16"    = Int16Column { columnName = name }
createColumn name "Int32"    = Int32Column { columnName = name }
createColumn name "Int64"    = Int64Column { columnName = name }
createColumn name "UInt8"    = UInt8Column { columnName = name }
createColumn name "UInt16"   = UInt16Column { columnName = name }
createColumn name "UInt32"   = UInt32Column { columnName = name }
createColumn name "UInt64"   = UInt64Column { columnName = name }
createColumn name "Float32"  = Float32Column { columnName = name }
createColumn name "Float64"  = Float64Column { columnName = name }
createColumn name "Date"     = DateColumn { columnName = name }
createColumn name "DateTime" = DateTimeColumn { columnName = name }

readValue :: Socket -> Column -> IO SqlValue
readValue sock (StringColumn _) =
  fmap toSql $ D.readString sock
readValue sock (Int8Column _) =
  fmap (iToSql . fromIntegral) $ D.readInt8 sock
readValue sock (Int16Column _) =
  fmap (iToSql . fromIntegral) $ D.readInt16 sock
readValue sock (Int32Column _) =
  fmap toSql $ D.readInt32 sock
readValue sock (Int64Column _) =
  fmap toSql $ D.readInt64 sock
readValue sock (UInt8Column _) =
  fmap (toSql . toWord32) $ D.readWord8 sock
readValue sock (UInt16Column _) =
  fmap (toSql . toWord32) $ D.readWord16 sock
readValue sock (UInt32Column _) =
  fmap toSql $ D.readWord32 sock
readValue sock (UInt64Column _) =
  fmap toSql $ D.readWord64 sock
readValue sock (Float32Column _) =
  fmap (toSql . toDouble) $ D.readFloat32 sock
readValue sock (Float64Column _) =
  fmap toSql $ D.readFloat64 sock
readValue sock (DateColumn _) =
  fmap toSql $ D.readDate sock -- TODO: timezone
readValue sock (DateTimeColumn _) =
  fmap toSql $ D.readDateTime sock -- TODO: timezone

toWord32 :: Integral a => a -> Word32
toWord32 = fromIntegral

toDouble :: Float -> Double
toDouble = realToFrac