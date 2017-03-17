module Models.NewStoryData exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Story as Story


{-| The data for the new story page.

`editingStory` is because this page is reused for editing the basic information
of existing stories as well.
-}
type alias NewStoryData =
    { newStory : Story.NewStory
    , editingStory : Story.Story
    , tagInput : String
    , editingStoryTagInput : String
    }


{-| NewStoryData encoder.
-}
encoder : NewStoryData -> Encode.Value
encoder newStoryData =
    Encode.object
        [ ( "newStory", Story.newStoryEncoder newStoryData.newStory )
        , ( "editingStory", Story.encoder newStoryData.editingStory )
        , ( "tagInput", Encode.string newStoryData.tagInput )
        , ( "editingStoryTagInput", Encode.string newStoryData.editingStoryTagInput )
        ]


{-| NewStoryData decoder.
-}
decoder : Decode.Decoder NewStoryData
decoder =
    decode NewStoryData
        |> required "newStory" Story.newStoryDecoder
        |> required "editingStory" Story.decoder
        |> required "tagInput" Decode.string
        |> required "editingStoryTagInput" Decode.string


{-| Default new story data, completely empty.
-}
defaultNewStoryData : NewStoryData
defaultNewStoryData =
    { newStory = Story.defaultNewStory
    , editingStory = Story.blankStory
    , tagInput = ""
    , editingStoryTagInput = ""
    }


{-| Updates the `newStory`.
-}
updateNewStory : (Story.NewStory -> Story.NewStory) -> NewStoryData -> NewStoryData
updateNewStory newStoryUpdater newStoryData =
    { newStoryData
        | newStory = newStoryUpdater newStoryData.newStory
    }


{-| Updates the `editingStory`.
-}
updateEditStory : (Story.Story -> Story.Story) -> NewStoryData -> NewStoryData
updateEditStory editingStoryUpdater newStoryData =
    { newStoryData
        | editingStory = editingStoryUpdater newStoryData.editingStory
    }


{-| Updates the `name` in `newStory`.
-}
updateName : String -> NewStoryData -> NewStoryData
updateName newName =
    updateNewStory
        (\newStory ->
            { newStory
                | name = newName
            }
        )


{-| Updates the `name` in `editingStory`.
-}
updateEditName : String -> NewStoryData -> NewStoryData
updateEditName newName =
    updateEditStory
        (\editingStory ->
            { editingStory
                | name = newName
            }
        )


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


{-| Updates the `description` in `editingStory`.
-}
updateEditDescription : String -> NewStoryData -> NewStoryData
updateEditDescription newDescription =
    updateEditStory
        (\editingStory ->
            { editingStory
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


{-| Updates the `editingStoryTagInput`.
-}
updateEditTagInput : String -> NewStoryData -> NewStoryData
updateEditTagInput newTagInput newStoryData =
    { newStoryData
        | editingStoryTagInput = newTagInput
    }


{-| Adds a new tag to the `newStory` if it's unique and not empty.
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


{-| Adds a new tag to the `editingStory` if it's unique and not empty.
-}
newEditTag : String -> NewStoryData -> NewStoryData
newEditTag newTag newStoryData =
    let
        modelWithNewTags =
            if String.isEmpty newTag || List.member newTag newStoryData.editingStory.tags then
                newStoryData
            else
                updateEditStory
                    (\editingStory ->
                        { editingStory
                            | tags = editingStory.tags ++ [ newTag ]
                        }
                    )
                    newStoryData
    in
        updateEditTagInput "" modelWithNewTags


{-| Removes a tag from the `newStory` if it exists in the tags.
-}
removeTag : String -> NewStoryData -> NewStoryData
removeTag oldTag =
    updateNewStory
        (\newStory ->
            { newStory
                | tags = List.filter ((/=) oldTag) newStory.tags
            }
        )


{-| Removes a tag from the `editingStory` if it exists in the tags.
-}
removeEditTag : String -> NewStoryData -> NewStoryData
removeEditTag oldTag =
    updateEditStory
        (\editingStory ->
            { editingStory
                | tags = List.filter ((/=) oldTag) editingStory.tags
            }
        )


{-| Returns True if the name tab is fileld in.
-}
nameTabFilledIn : NewStoryData -> Bool
nameTabFilledIn =
    .newStory >> .name >> String.isEmpty >> not


{-| Returns True if the name tab is filled in for the story being editd.
-}
editingNameTabFilledIn : NewStoryData -> Bool
editingNameTabFilledIn =
    .editingStory >> .name >> String.isEmpty >> not


{-| Returns True if the description tab is filled in.
-}
descriptionTabFilledIn : NewStoryData -> Bool
descriptionTabFilledIn =
    .newStory >> .description >> String.isEmpty >> not


{-| Returns True if the description tab is filled for the story being edited.
-}
editingDescriptionTabFilledIn : NewStoryData -> Bool
editingDescriptionTabFilledIn =
    .editingStory >> .description >> String.isEmpty >> not


{-| Returns True if the tags tab is filled in.
-}
tagsTabFilledIn : NewStoryData -> Bool
tagsTabFilledIn =
    .newStory >> .tags >> List.isEmpty >> not


{-| Returns True if the tags tab is filled in for the story being edited.
-}
editingTagsTabFilledIn : NewStoryData -> Bool
editingTagsTabFilledIn =
    .editingStory >> .tags >> List.isEmpty >> not


{-| Returns true if the new story is ready for publication.
-}
newStoryDataReadyForPublication : NewStoryData -> Bool
newStoryDataReadyForPublication newStoryData =
    nameTabFilledIn newStoryData
        && descriptionTabFilledIn newStoryData
        && tagsTabFilledIn newStoryData


{-| Returns true if the editing story data is ready to be saved.
-}
editingStoryDataReadyForSave : NewStoryData -> Bool
editingStoryDataReadyForSave newStoryData =
    editingNameTabFilledIn newStoryData
        && editingDescriptionTabFilledIn newStoryData
        && editingTagsTabFilledIn newStoryData
