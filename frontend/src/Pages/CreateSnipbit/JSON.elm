module Pages.CreateSnipbit.JSON exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import JSON.HighlightedComment
import JSON.Language
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.CreateSnipbit.Model exposing (..)


{-| `CreateSnipbitModel` encoder.
-}
encoder : Model -> Encode.Value
encoder snipbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull JSON.Language.encoder snipbitCreateData.language
          )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow"
          , Encode.int snipbitCreateData.languageListHowManyToShow
          )
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
                    JSON.HighlightedComment.maybeEncoder
                    snipbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string snipbitCreateData.introduction )
        , ( "conclusion", Encode.string snipbitCreateData.conclusion )
        , ( "previewMarkdown", Encode.bool snipbitCreateData.previewMarkdown )
        ]


{-| `CreateSnipbitModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "language" (Decode.maybe JSON.Language.decoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageListHowManyToShow" (Decode.int)
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required "highlightedComments"
            (Decode.array JSON.HighlightedComment.maybeDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "previewMarkdown" Decode.bool


{-| `SnipbitForPublication` encoder.
-}
publicationEncoder : SnipbitForPublication -> Encode.Value
publicationEncoder snipbitForPublication =
    Encode.object
        [ ( "language", JSON.Language.encoder snipbitForPublication.language )
        , ( "name", Encode.string snipbitForPublication.name )
        , ( "description", Encode.string snipbitForPublication.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string snipbitForPublication.tags
          )
        , ( "code", Encode.string snipbitForPublication.code )
        , ( "introduction", Encode.string snipbitForPublication.introduction )
        , ( "conclusion", Encode.string snipbitForPublication.conclusion )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    JSON.HighlightedComment.encoder
                    snipbitForPublication.highlightedComments
          )
        ]


{-| `SnipbitForPublication` decoder.
-}
publicationDecoder : Decode.Decoder SnipbitForPublication
publicationDecoder =
    decode SnipbitForPublication
        |> required "language" JSON.Language.decoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments"
            (Decode.array JSON.HighlightedComment.decoder)
