module Models.Story exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Tidbit as Tidbit


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


{-| The expanded-story model.

NOTE: Currently expanded pages are just tidbits, but in the future this may need
to as we may have tidbits AND quizzes etc...
-}
type alias ExpandedStory =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , expandedPages : List Tidbit.Tidbit
    }


{-| A new story being created, does not yet contain any db-added fields.

This data structure can also represent the information for editing a story.
-}
type alias NewStory =
    { name : String
    , description : String
    , tags : List String
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


{-| ExpandedStory encoder.
-}
expandedStoryEncoder : ExpandedStory -> Encode.Value
expandedStoryEncoder expandedStory =
    Encode.object
        [ ( "id", Encode.string expandedStory.id )
        , ( "author", Encode.string expandedStory.author )
        , ( "name", Encode.string expandedStory.name )
        , ( "description", Encode.string expandedStory.description )
        , ( "tags", Encode.list <| List.map Encode.string expandedStory.tags )
        , ( "expandedPages", Encode.list <| List.map Tidbit.encoder expandedStory.expandedPages )
        ]


{-| ExpandedStory decoder.
-}
expandedStoryDecoder : Decode.Decoder ExpandedStory
expandedStoryDecoder =
    decode ExpandedStory
        |> required "id" Decode.string
        |> required "author" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "expandedPages" (Decode.list Tidbit.decoder)


{-| NewStory encoder.
-}
newStoryEncoder : NewStory -> Encode.Value
newStoryEncoder newStory =
    Encode.object
        [ ( "name", Encode.string newStory.name )
        , ( "description", Encode.string newStory.description )
        , ( "tags", Encode.list <| List.map Encode.string newStory.tags )
        ]


{-| NewStory decoder.
-}
newStoryDecoder : Decode.Decoder NewStory
newStoryDecoder =
    decode NewStory
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)


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


{-| An empty new story.
-}
defaultNewStory : NewStory
defaultNewStory =
    { name = ""
    , description = ""
    , tags = []
    }


{-| A completely blank story.
-}
blankStory : Story
blankStory =
    { id = ""
    , author = ""
    , name = ""
    , description = ""
    , tags = []
    , pages = []
    }
