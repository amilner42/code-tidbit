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
    , createStage : BasicTidbitCreateStage
    , name : String
    , description : String
    }


{-| The stages of creating a tidbit.
-}
type BasicTidbitCreateStage
    = Name
    | Description
    | Language
    | Tags
    | Tidbit


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
        , ( "createStage"
          , basicTidbitCreateStageCacheEncoder basicTidbitCreateData.createStage
          )
        , ( "name", Encode.string basicTidbitCreateData.name )
        , ( "description", Encode.string basicTidbitCreateData.description )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    Decode.map6 BasicTidbitCreateData
        (Decode.field "language" (Decode.maybe languageCacheDecoder))
        (Decode.field "languageQueryACState" (Decode.succeed AC.empty))
        (Decode.field "languageQuery" Decode.string)
        (Decode.field "createStage" basicTidbitCreateStageCacheDecoder)
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)


{-| BasicTidbitCreateStage `cacheEncoder`.
-}
basicTidbitCreateStageCacheEncoder : BasicTidbitCreateStage -> Encode.Value
basicTidbitCreateStageCacheEncoder basicTidbitCreateStage =
    Encode.string (toString basicTidbitCreateStage)


{-| BasicTidbitCreateStage `cacheDecoder`.
-}
basicTidbitCreateStageCacheDecoder : Decode.Decoder BasicTidbitCreateStage
basicTidbitCreateStageCacheDecoder =
    let
        fromStringDecoder encodedCreateStage =
            case encodedCreateStage of
                "Name" ->
                    Decode.succeed Name

                "Description" ->
                    Decode.succeed Description

                "Language" ->
                    Decode.succeed Language

                "Tags" ->
                    Decode.succeed Tags

                "Tidbit" ->
                    Decode.succeed Tidbit

                _ ->
                    Decode.fail <|
                        encodedCreateStage
                            ++ " is not a valid encoded basic tidbit create stage."
    in
        Decode.andThen fromStringDecoder Decode.string
