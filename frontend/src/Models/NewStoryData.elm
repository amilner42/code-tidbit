module Models.NewStoryData exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Story as Story


{-| The data for the new story page.
-}
type alias NewStoryData =
    { newStory : Story.NewStory
    , tagInput : String
    }


{-| NewStoryData encoder.
-}
encoder : NewStoryData -> Encode.Value
encoder newStoryData =
    Encode.object
        [ ( "newStory", Story.newStoryEncoder newStoryData.newStory )
        , ( "tagInput", Encode.string newStoryData.tagInput )
        ]


{-| NewStoryData decoder.
-}
decoder : Decode.Decoder NewStoryData
decoder =
    decode NewStoryData
        |> required "newStory" Story.newStoryDecoder
        |> required "tagInput" Decode.string


{-| Default new story data, completely empty.
-}
defaultNewStoryData : NewStoryData
defaultNewStoryData =
    { newStory = Story.defaultNewStory
    , tagInput = ""
    }


{-| Updates the `newStory`.
-}
updateNewStory : (Story.NewStory -> Story.NewStory) -> NewStoryData -> NewStoryData
updateNewStory newStoryUpdater newStoryData =
    { newStoryData
        | newStory = newStoryUpdater newStoryData.newStory
    }


{-| Updates the `name` in `newStory`.
-}
updateName : String -> NewStoryData -> NewStoryData
updateName newName newStoryData =
    updateNewStory
        (\newStory ->
            { newStory
                | name = newName
            }
        )
        newStoryData


{-| Updates the `description` in `newStory`.
-}
updateDescription : String -> NewStoryData -> NewStoryData
updateDescription newDescription =
    updateNewStory
        (\newStory ->
            { newStory
                | description = newDescription
            }
        )


{-| Updates the `tagInput`.
-}
updateTagInput : String -> NewStoryData -> NewStoryData
updateTagInput newTagInput newStoryData =
    { newStoryData
        | tagInput = newTagInput
    }


{-| Adds a new tag if it's unique and not empty.
-}
newTag : String -> NewStoryData -> NewStoryData
newTag newTag newStoryData =
    let
        modelWithNewTags =
            if String.isEmpty newTag || List.member newTag newStoryData.newStory.tags then
                newStoryData
            else
                updateNewStory
                    (\newStory ->
                        { newStory
                            | tags = newStory.tags ++ [ newTag ]
                        }
                    )
                    newStoryData
    in
        updateTagInput "" modelWithNewTags


{-| Removes a tag if it exists in the tags.
-}
removeTag : String -> NewStoryData -> NewStoryData
removeTag oldTag =
    updateNewStory
        (\newStory ->
            { newStory
                | tags = List.filter ((/=) oldTag) newStory.tags
            }
        )


{-| Returns True if the name tab is fileld in.
-}
nameTabFilledIn : NewStoryData -> Bool
nameTabFilledIn =
    .newStory >> .name >> String.isEmpty >> not


{-| Returns True if the description tab is filled in.
-}
descriptionTabFilledIn : NewStoryData -> Bool
descriptionTabFilledIn =
    .newStory >> .description >> String.isEmpty >> not


{-| Returns True if the tags tab is filled in.
-}
tagsTabFilledIn : NewStoryData -> Bool
tagsTabFilledIn =
    .newStory >> .tags >> List.isEmpty >> not


{-| Returns true if the new story is ready for publication.
-}
newStoryDataReadyForPublication : NewStoryData -> Bool
newStoryDataReadyForPublication newStoryData =
    nameTabFilledIn newStoryData
        && descriptionTabFilledIn newStoryData
        && tagsTabFilledIn newStoryData
