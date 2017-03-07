module Models.Story exposing (..)

import Date
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer


{-| The story model.
-}
type alias Story =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , tidbitPointers : List TidbitPointer.TidbitPointer
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| The expanded-story model.
-}
type alias ExpandedStory =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , tidbits : List Tidbit.Tidbit
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| A new story being created, does not yet contain any db-added fields.

This data structure can also represent the information for editing a story.
-}
type alias NewStory =
    { name : String
    , description : String
    , tags : List String
    }


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
        , ( "tidbitPointers", Encode.list <| List.map TidbitPointer.encoder story.tidbitPointers )
        , ( "createdAt", Util.dateEncoder story.createdAt )
        , ( "lastModified", Util.dateEncoder story.lastModified )
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
        |> required "tidbitPointers" (Decode.list TidbitPointer.decoder)
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder


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
        , ( "tidbits", Encode.list <| List.map Tidbit.encoder expandedStory.tidbits )
        , ( "createdAt", Util.dateEncoder expandedStory.createdAt )
        , ( "lastModified", Util.dateEncoder expandedStory.lastModified )
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
        |> required "tidbits" (Decode.list Tidbit.decoder)
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder


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


{-| An empty new story.
-}
defaultNewStory : NewStory
defaultNewStory =
    { name = ""
    , description = ""
    , tags = []
    }


{-| A completely blank story.

Meaningless stub-dates are used for the dates.
-}
blankStory : Story
blankStory =
    { id = ""
    , author = ""
    , name = ""
    , description = ""
    , tags = []
    , tidbitPointers = []
    , createdAt = Date.fromTime 0
    , lastModified = Date.fromTime 0
    }
