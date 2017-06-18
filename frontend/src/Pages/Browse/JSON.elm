module Pages.Browse.JSON exposing (..)

import DefaultServices.Util exposing (justValueOrNull)
import JSON.Language
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
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
        , ( "contentFilterAuthor"
          , Encode.object
                [ ( "emailInput", Encode.string <| Tuple.first model.contentFilterAuthor )
                , ( "authorForInput", justValueOrNull Encode.string <| Tuple.second model.contentFilterAuthor )
                ]
          )
        , ( "mostRecentSearchSettings", Encode.null )
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
        |> required "contentFilterAuthor"
            (decode (,)
                |> required "emailInput" Decode.string
                |> required "authorForInput" (Decode.maybe Decode.string)
            )
        |> hardcoded Nothing
