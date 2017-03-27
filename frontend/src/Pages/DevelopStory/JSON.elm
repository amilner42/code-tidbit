module Pages.DevelopStory.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Story
import JSON.Tidbit
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.DevelopStory.Model exposing (..)


{-| `DevelopStory` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "story", Util.justValueOrNull JSON.Story.expandedStoryEncoder model.story )
        , ( "tidbitsToAdd", Encode.list <| List.map JSON.Tidbit.encoder model.tidbitsToAdd )
        ]


{-| `DevelopStory` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "story" (Decode.maybe JSON.Story.expandedStoryDecoder)
        |> required "tidbitsToAdd" (Decode.list JSON.Tidbit.decoder)
