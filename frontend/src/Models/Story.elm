module Models.Story exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| The story model.
-}
type alias Story =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , pages : List StoryPage
    }


{-| A new story being created, does not yet contain any db-added fields.
-}
type alias NewStory =
    { author : String
    , name : String
    , description : String
    , tags : List String
    , pages : List StoryPage
    }


{-| A single "page" from a story.
-}
type alias StoryPage =
    { storyType : StoryPageType
    , targetID : String
    }


{-| The current possible pages.
-}
type StoryPageType
    = Snipbit
    | Bigbit


{-| Story encoder.
-}
storyEncoder : Story -> Encode.Value
storyEncoder story =
    Encode.object
        [ ( "id", Encode.string story.id )
        , ( "author", Encode.string story.author )
        , ( "name", Encode.string story.name )
        , ( "description", Encode.string story.description )
        , ( "tags", Encode.list <| List.map Encode.string story.tags )
        , ( "pages", Encode.list <| List.map storyPageEncoder story.pages )
        ]


{-| Story decoder.
-}
storyDecoder : Decode.Decoder Story
storyDecoder =
    decode Story
        |> required "id" Decode.string
        |> required "author" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "pages" (Decode.list storyPageDecoder)


{-| NewStory encoder.
-}
newStoryEncoder : NewStory -> Encode.Value
newStoryEncoder newStory =
    Encode.object
        [ ( "author", Encode.string newStory.author )
        , ( "name", Encode.string newStory.name )
        , ( "description", Encode.string newStory.description )
        , ( "tags", Encode.list <| List.map Encode.string newStory.tags )
        , ( "pages", Encode.list <| List.map storyPageEncoder newStory.pages )
        ]


{-| NewStory decoder.
-}
newStoryDecoder : Decode.Decoder NewStory
newStoryDecoder =
    decode NewStory
        |> required "author" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "pages" (Decode.list storyPageDecoder)


{-| StoryPage encoder.
-}
storyPageEncoder : StoryPage -> Encode.Value
storyPageEncoder storyPage =
    Encode.object
        [ ( "storyType", storyPageTypeEncoder storyPage.storyType )
        , ( "targetID", Encode.string storyPage.targetID )
        ]


{-| StoryPage decoder.
-}
storyPageDecoder : Decode.Decoder StoryPage
storyPageDecoder =
    decode StoryPage
        |> required "storyType" storyPageTypeDecoder
        |> required "targetID" Decode.string


{-| StoryPageType encoder.
-}
storyPageTypeEncoder : StoryPageType -> Encode.Value
storyPageTypeEncoder storyPageType =
    case storyPageType of
        Snipbit ->
            Encode.int 1

        Bigbit ->
            Encode.int 2


{-| StoryPageType decoder.
-}
storyPageTypeDecoder : Decode.Decoder StoryPageType
storyPageTypeDecoder =
    let
        fromIntDecoder encodedInt =
            case encodedInt of
                1 ->
                    Decode.succeed Snipbit

                2 ->
                    Decode.succeed Bigbit

                _ ->
                    Decode.fail <| "That is not a valid encoded storyPageType: " ++ (toString encodedInt)
    in
        Decode.int
            |> Decode.andThen fromIntDecoder
