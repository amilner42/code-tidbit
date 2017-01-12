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
    , name : String
    , description : String
    , tags : List String
    , tagInput : String
    , code : String
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
        , ( "name", Encode.string basicTidbitCreateData.name )
        , ( "description", Encode.string basicTidbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string basicTidbitCreateData.tags
          )
        , ( "tagInput", Encode.string basicTidbitCreateData.tagInput )
        , ( "code", Encode.string basicTidbitCreateData.code )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    Decode.map8 BasicTidbitCreateData
        (Decode.field "language" (Decode.maybe languageCacheDecoder))
        (Decode.field "languageQueryACState" (Decode.succeed AC.empty))
        (Decode.field "languageQuery" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "tags" <| Decode.list Decode.string)
        (Decode.field "tagInput" Decode.string)
        (Decode.field "code" Decode.string)
