module Pages.Browse.JSON exposing (..)

import DefaultServices.Util exposing (justValueOrNull)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Language
import Pages.Browse.Model exposing (..)


{-| `Browse` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "content", Encode.null )
        , ( "pageNumber", Encode.null )
        , ( "noMoreContent", Encode.null )
        , ( "searchQuery", Encode.string model.searchQuery )
        , ( "showNewContentMessage", Encode.null )
        , ( "showAdvancedSearchOptions", Encode.bool model.showAdvancedSearchOptions )
        , ( "contentFilterSnipbits", Encode.bool model.contentFilterSnipbits )
        , ( "contentFilterBigbits", Encode.bool model.contentFilterBigbits )
        , ( "contentFilterStories", Encode.bool model.contentFilterStories )
        , ( "contentFilterIncludeEmptyStories", Encode.bool model.contentFilterIncludeEmptyStories )
        , ( "contentFilterLanguage", justValueOrNull JSON.Language.encoder model.contentFilterLanguage )
        ]


{-| `Browse` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> hardcoded Nothing
        |> hardcoded 1
        |> hardcoded False
        |> required "searchQuery" Decode.string
        |> hardcoded False
        |> required "showAdvancedSearchOptions" Decode.bool
        |> required "contentFilterSnipbits" Decode.bool
        |> required "contentFilterBigbits" Decode.bool
        |> required "contentFilterStories" Decode.bool
        |> required "contentFilterIncludeEmptyStories" Decode.bool
        |> required "contentFilterLanguage" (Decode.maybe JSON.Language.decoder)
