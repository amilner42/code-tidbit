module Models.BasicTidbit exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)


{-| The data for a basic tidbit being created.
-}
type alias BasicTidbitCreateData =
    { language : Maybe Language
    }


{-| BasicTidbitCreateData `cacheEncoder`.
-}
createDataCacheEncoder : BasicTidbitCreateData -> Encode.Value
createDataCacheEncoder basicTidbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull
                languageCacheEncoder
                basicTidbitCreateData.language
          )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    Decode.map BasicTidbitCreateData
        (Decode.field "language" (Decode.maybe languageCacheDecoder))
