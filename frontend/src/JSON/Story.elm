module JSON.Story exposing (..)

import DefaultServices.Util as Util
import JSON.Tidbit
import JSON.TidbitPointer
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.Story exposing (..)


{-| `Story` encoder.
-}
encoder : Story -> Encode.Value
encoder story =
    Encode.object
        [ ( "id", Encode.string story.id )
        , ( "author", Encode.string story.author )
        , ( "name", Encode.string story.name )
        , ( "description", Encode.string story.description )
        , ( "tags", Encode.list <| List.map Encode.string story.tags )
        , ( "tidbitPointers", Encode.list <| List.map JSON.TidbitPointer.encoder story.tidbitPointers )
        , ( "createdAt", Util.dateEncoder story.createdAt )
        , ( "lastModified", Util.dateEncoder story.lastModified )
        , ( "userHasCompleted", Util.justValueOrNull (Encode.list << List.map Encode.bool) story.userHasCompleted )
        ]


{-| `Story` decoder.
-}
decoder : Decode.Decoder Story
decoder =
    decode Story
        |> required "id" Decode.string
        |> required "author" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tidbitPointers" (Decode.list JSON.TidbitPointer.decoder)
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder
        |> optional "userHasCompleted" (Decode.maybe <| Decode.list Decode.bool) Nothing


{-| `ExpandedStory` encoder.
-}
expandedStoryEncoder : ExpandedStory -> Encode.Value
expandedStoryEncoder expandedStory =
    Encode.object
        [ ( "id", Encode.string expandedStory.id )
        , ( "author", Encode.string expandedStory.author )
        , ( "name", Encode.string expandedStory.name )
        , ( "description", Encode.string expandedStory.description )
        , ( "tags", Encode.list <| List.map Encode.string expandedStory.tags )
        , ( "tidbits", Encode.list <| List.map JSON.Tidbit.encoder expandedStory.tidbits )
        , ( "createdAt", Util.dateEncoder expandedStory.createdAt )
        , ( "lastModified", Util.dateEncoder expandedStory.lastModified )
        , ( "userHasCompleted", Util.justValueOrNull (Encode.list << List.map Encode.bool) expandedStory.userHasCompleted )
        ]


{-| `ExpandedStory` decoder.
-}
expandedStoryDecoder : Decode.Decoder ExpandedStory
expandedStoryDecoder =
    decode ExpandedStory
        |> required "id" Decode.string
        |> required "author" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tidbits" (Decode.list JSON.Tidbit.decoder)
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder
        |> optional "userHasCompleted" (Decode.maybe <| Decode.list Decode.bool) Nothing


{-| `NewStory` encoder.
-}
newStoryEncoder : NewStory -> Encode.Value
newStoryEncoder newStory =
    Encode.object
        [ ( "name", Encode.string newStory.name )
        , ( "description", Encode.string newStory.description )
        , ( "tags", Encode.list <| List.map Encode.string newStory.tags )
        ]


{-| `NewStory` decoder.
-}
newStoryDecoder : Decode.Decoder NewStory
newStoryDecoder =
    decode NewStory
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
