module Database.HDBC.ClickHouse.Protocol.Data where

import Data.Bits
import Data.IP
import Data.List (intersperse, isPrefixOf, isSuffixOf, unfoldr)
import Data.Time
import Data.Word
import Database.HDBC.ColTypes
import Database.HDBC.SqlValue
import Database.HDBC.ClickHouse.Protocol
import Network.Socket (Socket)
import Numeric (showHex)

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
} | UUIDColumn {
    columnName :: String
} | IPv4Column {
    columnName :: String
} | IPv6Column {
    columnName :: String
} | FixedStringColumn {
    columnName :: String,
    fixedStringSize :: Int
} | ArrayColumn {
    columnName :: String,
    itemType :: Column
} | NullableColumn {
    columnName :: String,
    itemType :: Column
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
createColumn name "UUID"     = UUIDColumn { columnName = name }
createColumn name "IPv4"     = IPv4Column { columnName = name }
createColumn name "IPv6"     = IPv6Column { columnName = name }
createColumn name typ | isPrefixOf "FixedString(" typ && isSuffixOf ")" typ =
  FixedStringColumn { columnName = name, fixedStringSize = getFixedStringSize typ }
createColumn name typ | isPrefixOf "Array(" typ && isSuffixOf ")" typ =
  ArrayColumn { columnName = name, itemType = getItemType name (length "Array(") typ }
createColumn name typ | isPrefixOf "Nullable(" typ && isSuffixOf ")" typ =
  NullableColumn { columnName = name, itemType = getItemType name (length "Nullable(") typ }

getFixedStringSize :: String -> Int
getFixedStringSize typ =
  read $ (drop (length "FixedString(") . init) typ

getItemType :: String -> Int -> String -> Column
getItemType name prefixSize typ =
  createColumn ("[" ++ name ++ "]") $ (drop prefixSize . init) typ

getSqlColDesc :: Column -> SqlColDesc
getSqlColDesc (StringColumn _) = SqlColDesc {
  colType = SqlVarCharT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Int8Column _) = SqlColDesc {
  colType = SqlTinyIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Int16Column _) = SqlColDesc {
  colType = SqlSmallIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Int32Column _) = SqlColDesc {
  colType = SqlIntegerT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Int64Column _) = SqlColDesc {
  colType = SqlBigIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (UInt8Column _) = SqlColDesc {
  colType = SqlTinyIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (UInt16Column _) = SqlColDesc {
  colType = SqlSmallIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (UInt32Column _) = SqlColDesc {
  colType = SqlIntegerT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (UInt64Column _) = SqlColDesc {
  colType = SqlBigIntT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Float32Column _) = SqlColDesc {
  colType = SqlFloatT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (Float64Column _) = SqlColDesc {
  colType = SqlDoubleT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (DateColumn _) = SqlColDesc {
  colType = SqlDateT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (DateTimeColumn _) = SqlColDesc {
  colType = SqlTimeT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (UUIDColumn _) = SqlColDesc {
  colType = SqlCharT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (IPv4Column _) = SqlColDesc {
  colType = SqlCharT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (IPv6Column _) = SqlColDesc {
  colType = SqlCharT,
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (FixedStringColumn _ size) = SqlColDesc {
  colType = SqlCharT,
  colSize = Just size,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (ArrayColumn _ _) = SqlColDesc {
  colType = SqlUnknownT "Array",
  colSize = Nothing,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just False
}
getSqlColDesc (NullableColumn _ itemType) = SqlColDesc {
  colType = colType itemSqlColDesc,
  colSize = colSize itemSqlColDesc,
  colOctetLength = Nothing,
  colDecDigits = Nothing,
  colNullable = Just True
}
  where itemSqlColDesc = getSqlColDesc itemType

readValue :: Socket -> Column -> Config -> Int -> IO [SqlValue]
readValue sock (StringColumn _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readString sock
readValue sock (Int8Column _) _ numRows =
  readEachValue numRows $ fmap (iToSql . fromIntegral) $ D.readInt8 sock
readValue sock (Int16Column _) _ numRows =
  readEachValue numRows $ fmap (iToSql . fromIntegral) $ D.readInt16 sock
readValue sock (Int32Column _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readInt32 sock
readValue sock (Int64Column _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readInt64 sock
readValue sock (UInt8Column _) _ numRows =
  readEachValue numRows $ fmap (toSql . toWord32) $ D.readWord8 sock
readValue sock (UInt16Column _) _ numRows =
  readEachValue numRows $ fmap (toSql . toWord32) $ D.readWord16 sock
readValue sock (UInt32Column _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readWord32 sock
readValue sock (UInt64Column _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readWord64 sock
readValue sock (Float32Column _) _ numRows =
  readEachValue numRows $ fmap (toSql . toDouble) $ D.readFloat32 sock
readValue sock (Float64Column _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readFloat64 sock
readValue sock (DateColumn _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readDate sock -- TODO: timezone
readValue sock (DateTimeColumn _) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readDateTime sock -- TODO: timezone
readValue sock (FixedStringColumn _ size) _ numRows =
  readEachValue numRows $ fmap toSql $ D.readFixedString sock size
readValue sock (UUIDColumn _) _ numRows =
  readEachValue numRows read
    where
      read = do
        bytes <- mapM (\_ -> fmap fromIntegral $ D.readWord8 sock) [1..16]
        let uuids = foldl toUUID ("", "", "", "", "") $ zip bytes [0..]
        return $ toSql $ concat $ intersperse "-" $ tapleTolist uuids
      toUUID (uuid1, uuid2, uuid3, uuid4, uuid5) (byte, index)
        | index >= 4  && index <= 7  = (toHex byte uuid1, uuid2, uuid3, uuid4, uuid5)
        | index >= 2  && index <= 3  = (uuid1, toHex byte uuid2, uuid3, uuid4, uuid5)
        | index >= 0  && index <= 1  = (uuid1, uuid2, toHex byte uuid3, uuid4, uuid5)
        | index >= 14 && index <= 15 = (uuid1, uuid2, uuid3, toHex byte uuid4, uuid5)
        | index >= 8  && index <= 13 = (uuid1, uuid2, uuid3, uuid4, toHex byte uuid5)
      toHex b s
        | b <= 15   = '0' : (showHex b s)
        | otherwise = showHex b s
      tapleTolist (uuid1, uuid2, uuid3, uuid4, uuid5) = [uuid1, uuid2, uuid3, uuid4, uuid5]
readValue sock (IPv4Column _) _ numRows =
  readEachValue numRows read
    where
      read = do
        bytes <- mapM (\_ -> fmap fromIntegral $ D.readWord8 sock) [1..4]
        let ip = toIPv4 $ reverse bytes
        return $ toSql $ show ip
readValue sock (IPv6Column _) _ numRows =
  readEachValue numRows read
    where
      read = do
        bytes <- mapM (\_ -> fmap fromIntegral $ D.readWord8 sock) [1..16]
        let ip = toIPv6 $ unfoldr f bytes
        return $ toSql $ show ip
      f (x:y:zs) = Just ((x `shiftL` 8) .|. y, zs)
      f _        = Nothing
readValue sock (ArrayColumn _ itemType) config numRows = do
  offsets <- mapM (\_ -> fmap fromIntegral $ D.readWord64 sock) [1..numRows]
  fmap (map $ joinSqlValues config) $ mapM (\offset -> readValue sock itemType config offset) offsets
readValue sock (NullableColumn _ itemType) config numRows = do
  isNulls <- mapM (\_ -> D.readBool sock) [1..numRows]
  values <- readValue sock itemType config numRows
  return $ map f $ zip values isNulls
    where
      f (_, True) = SqlNull
      f (v, _   ) = v

readEachValue numRows f =
  mapM (\_ -> f) [1..numRows]

toWord32 :: Integral a => a -> Word32
toWord32 = fromIntegral

toDouble :: Float -> Double
toDouble = realToFrac
