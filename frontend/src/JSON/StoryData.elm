module JSON.StoryData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Story
import JSON.Tidbit
import Models.StoryData exposing (..)


{-| `StoryData` encoder.
-}
encoder : StoryData -> Encode.Value
encoder storyData =
    Encode.object
        [ ( "currentStory", Util.justValueOrNull JSON.Story.expandedStoryEncoder storyData.currentStory )
        , ( "tidbitsToAdd", Encode.list <| List.map JSON.Tidbit.encoder storyData.tidbitsToAdd )
        ]


{-| `StoryData` decoder.
-}
decoder : Decode.Decoder StoryData
decoder =
    decode StoryData
        |> required "currentStory" (Decode.maybe JSON.Story.expandedStoryDecoder)
        |> required "tidbitsToAdd" (Decode.list JSON.Tidbit.decoder)
