module Models.BasicTidbit exposing (..)

import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)


{-| The data for a basic tidbit being created.
-}
type alias BasicTidbitCreateData =
    { language : Maybe Language
    , languageQueryACState : AC.State
    , languageQuery : String
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
        , ( "languageQueryACState", Encode.null )
        , ( "languageQuery", Encode.string basicTidbitCreateData.languageQuery )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    Decode.map3 BasicTidbitCreateData
        (Decode.field "language" (Decode.maybe languageCacheDecoder))
        (Decode.field "languageQueryACState" (Decode.succeed AC.empty))
        (Decode.field "languageQuery" Decode.string)
