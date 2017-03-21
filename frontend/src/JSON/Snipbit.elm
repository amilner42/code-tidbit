module JSON.Snipbit exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.HighlightedComment as JSONHC
import Models.Snipbit exposing (..)
import Elements.Editor as Editor exposing (languageCacheDecoder, languageCacheEncoder)


{-| For DRY code to create encoders for `Snipbit` and `SnipbitForPublication`.
-}
createSnipbitEncoder model extraFields =
    Encode.object <|
        List.concat
            [ [ ( "language", languageCacheEncoder model.language )
              , ( "name", Encode.string model.name )
              , ( "description", Encode.string model.description )
              , ( "tags", Encode.list <| List.map Encode.string model.tags )
              , ( "code", Encode.string model.code )
              , ( "introduction", Encode.string model.introduction )
              , ( "conclusion", Encode.string model.conclusion )
              , ( "highlightedComments"
                , Encode.array <| Array.map JSONHC.encoder model.highlightedComments
                )
              ]
            , extraFields
            ]


{-| `Snipbit` encoder.
-}
encoder : Snipbit -> Encode.Value
encoder snipbit =
    createSnipbitEncoder
        snipbit
        [ ( "id", Encode.string snipbit.id )
        , ( "author", Encode.string snipbit.author )
        , ( "createdAt", Util.dateEncoder snipbit.createdAt )
        , ( "lastModified", Util.dateEncoder snipbit.lastModified )
        ]


{-| `Snipbit` decoder.
-}
decoder : Decode.Decoder Snipbit
decoder =
    decode Snipbit
        |> required "id" Decode.string
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array JSONHC.decoder)
        |> required "author" Decode.string
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder


{-| `SnipbitForPublication` encoder.
-}
publicationEncoder : SnipbitForPublication -> Encode.Value
publicationEncoder snipbitForPublication =
    createSnipbitEncoder snipbitForPublication []


{-| `SnipbitForPublication` decoder.
-}
publicationDecoder : Decode.Decoder SnipbitForPublication
publicationDecoder =
    decode SnipbitForPublication
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array JSONHC.decoder)


{-| `SnipbitCreateData` encoder.
-}
createDataEncoder : SnipbitCreateData -> Encode.Value
createDataEncoder snipbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull
                languageCacheEncoder
                snipbitCreateData.language
          )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow", Encode.int snipbitCreateData.languageListHowManyToShow )
        , ( "languageQuery", Encode.string snipbitCreateData.languageQuery )
        , ( "name", Encode.string snipbitCreateData.name )
        , ( "description", Encode.string snipbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string snipbitCreateData.tags
          )
        , ( "tagInput", Encode.string snipbitCreateData.tagInput )
        , ( "code", Encode.string snipbitCreateData.code )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    JSONHC.maybeEncoder
                    snipbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string snipbitCreateData.introduction )
        , ( "conclusion", Encode.string snipbitCreateData.conclusion )
        , ( "previewMarkdown", Encode.bool snipbitCreateData.previewMarkdown )
        ]


{-| `SnipbitCreateData` decoder.
-}
createDataDecoder : Decode.Decoder SnipbitCreateData
createDataDecoder =
    decode SnipbitCreateData
        |> required "language" (Decode.maybe languageCacheDecoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageListHowManyToShow" (Decode.int)
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required "highlightedComments" (Decode.array JSONHC.maybeDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "previewMarkdown" Decode.bool
