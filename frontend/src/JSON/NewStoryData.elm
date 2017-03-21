module JSON.NewStoryData exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Story as JSONStory
import Models.NewStoryData exposing (..)
import Models.Story as Story


{-| `NewStoryData` encoder.
-}
encoder : NewStoryData -> Encode.Value
encoder newStoryData =
    Encode.object
        [ ( "newStory", JSONStory.newStoryEncoder newStoryData.newStory )
        , ( "editingStory", JSONStory.encoder newStoryData.editingStory )
        , ( "tagInput", Encode.string newStoryData.tagInput )
        , ( "editingStoryTagInput", Encode.string newStoryData.editingStoryTagInput )
        ]


{-| `NewStoryData` decoder.
-}
decoder : Decode.Decoder NewStoryData
decoder =
    decode NewStoryData
        |> required "newStory" JSONStory.newStoryDecoder
        |> required "editingStory" JSONStory.decoder
        |> required "tagInput" Decode.string
        |> required "editingStoryTagInput" Decode.string
