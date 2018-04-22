module Pages.CreateSnipbit.JSON exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import JSON.Language
import JSON.Snipbit
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Pages.CreateSnipbit.Model exposing (..)


{-| `CreateSnipbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "language", Util.justValueOrNull JSON.Language.encoder model.language )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow", Encode.int model.languageListHowManyToShow )
        , ( "languageQuery", Encode.string model.languageQuery )
        , ( "name", Encode.string model.name )
        , ( "description", Encode.string model.description )
        , ( "tags", Encode.list <| List.map Encode.string model.tags )
        , ( "tagInput", Encode.string model.tagInput )
        , ( "code", Encode.string model.code )
        , ( "highlightedComments"
          , Encode.array <| Array.map JSON.Snipbit.maybeHCEncoder model.highlightedComments
          )
        , ( "introduction", Encode.string model.introduction )
        , ( "conclusion", Encode.string model.conclusion )
        , ( "previewMarkdown", Encode.bool model.previewMarkdown )
        , ( "confirmedRemoveFrame", Encode.bool False )
        ]


{-| `CreateSnipbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "language" (Decode.maybe JSON.Language.decoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageListHowManyToShow" Decode.int
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required "highlightedComments" (Decode.array JSON.Snipbit.maybeHCDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "previewMarkdown" Decode.bool
        |> required "confirmedRemoveFrame" Decode.bool


{-| `SnipbitForPublication` encoder.
-}
publicationEncoder : SnipbitForPublication -> Encode.Value
publicationEncoder snipbitForPublication =
    Encode.object
        [ ( "language", JSON.Language.encoder snipbitForPublication.language )
        , ( "name", Encode.string snipbitForPublication.name )
        , ( "description", Encode.string snipbitForPublication.description )
        , ( "tags", Encode.list <| List.map Encode.string snipbitForPublication.tags )
        , ( "code", Encode.string snipbitForPublication.code )
        , ( "introduction", Encode.string snipbitForPublication.introduction )
        , ( "conclusion", Encode.string snipbitForPublication.conclusion )
        , ( "highlightedComments"
          , Encode.array <| Array.map JSON.Snipbit.hcEncoder snipbitForPublication.highlightedComments
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
        |> required "highlightedComments" (Decode.array JSON.Snipbit.hcDecoder)
