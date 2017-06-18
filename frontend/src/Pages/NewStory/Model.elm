module Pages.NewStory.Model exposing (..)

import DefaultServices.Util as Util
import Models.Story as Story


{-| `NewStory` model.
-}
type alias Model =
    { newStory : Story.NewStory
    , editingStory : Story.Story
    , tagInput : String
    , editingStoryTagInput : String
    }


{-| Updates the `newStory`.
-}
updateNewStory : (Story.NewStory -> Story.NewStory) -> Model -> Model
updateNewStory newStoryUpdater newStoryData =
    { newStoryData | newStory = newStoryUpdater newStoryData.newStory }


{-| Updates the `editingStory`.
-}
updateEditStory : (Story.Story -> Story.Story) -> Model -> Model
updateEditStory editingStoryUpdater newStoryData =
    { newStoryData | editingStory = editingStoryUpdater newStoryData.editingStory }


{-| Updates the `name` in `newStory`.
-}
updateName : String -> Model -> Model
updateName newName =
    updateNewStory (\newStory -> { newStory | name = newName })


{-| Updates the `name` in `editingStory`.
-}
updateEditName : String -> Model -> Model
updateEditName newName =
    updateEditStory (\editingStory -> { editingStory | name = newName })


{-| Updates the `description` in `newStory`.
-}
updateDescription : String -> Model -> Model
updateDescription newDescription =
    updateNewStory (\newStory -> { newStory | description = newDescription })


{-| Updates the `description` in `editingStory`.
-}
updateEditDescription : String -> Model -> Model
updateEditDescription newDescription =
    updateEditStory (\editingStory -> { editingStory | description = newDescription })


{-| Updates the `tagInput`.
-}
updateTagInput : String -> Model -> Model
updateTagInput newTagInput newStoryData =
    { newStoryData | tagInput = newTagInput }


{-| Updates the `editingStoryTagInput`.
-}
updateEditTagInput : String -> Model -> Model
updateEditTagInput newTagInput newStoryData =
    { newStoryData | editingStoryTagInput = newTagInput }


{-| Adds a new tag to the `newStory` if it's unique and not empty.
-}
newTag : String -> Model -> Model
newTag newTag newStoryData =
    let
        modelWithNewTags =
            updateNewStory
                (\newStory -> { newStory | tags = Util.addUniqueNonEmptyString newTag newStory.tags })
                newStoryData
    in
    updateTagInput "" modelWithNewTags


{-| Adds a new tag to the `editingStory` if it's unique and not empty.
-}
newEditTag : String -> Model -> Model
newEditTag newTag newStoryData =
    let
        modelWithNewTags =
            updateEditStory
                (\editingStory -> { editingStory | tags = Util.addUniqueNonEmptyString newTag editingStory.tags })
                newStoryData
    in
    updateEditTagInput "" modelWithNewTags


{-| Removes a tag from the `newStory` if it exists in the tags.
-}
removeTag : String -> Model -> Model
removeTag oldTag =
    updateNewStory (\newStory -> { newStory | tags = List.filter ((/=) oldTag) newStory.tags })


{-| Removes a tag from the `editingStory` if it exists in the tags.
-}
removeEditTag : String -> Model -> Model
removeEditTag oldTag =
    updateEditStory (\editingStory -> { editingStory | tags = List.filter ((/=) oldTag) editingStory.tags })


{-| Returns True if the name tab is fileld in.
-}
nameTabFilledIn : Model -> Bool
nameTabFilledIn =
    .newStory >> .name >> Util.justStringInRange 1 50 >> Util.isNotNothing


{-| Returns True if the name tab is filled in for the story being editd.
-}
editingNameTabFilledIn : Model -> Bool
editingNameTabFilledIn =
    .editingStory >> .name >> Util.justStringInRange 1 50 >> Util.isNotNothing


{-| Returns True if the description tab is filled in.
-}
descriptionTabFilledIn : Model -> Bool
descriptionTabFilledIn =
    .newStory >> .description >> Util.justStringInRange 1 300 >> Util.isNotNothing


{-| Returns True if the description tab is filled for the story being edited.
-}
editingDescriptionTabFilledIn : Model -> Bool
editingDescriptionTabFilledIn =
    .editingStory >> .description >> Util.justStringInRange 1 300 >> Util.isNotNothing


{-| Returns True if the tags tab is filled in.
-}
tagsTabFilledIn : Model -> Bool
tagsTabFilledIn =
    .newStory >> .tags >> List.isEmpty >> not


{-| Returns True if the tags tab is filled in for the story being edited.
-}
editingTagsTabFilledIn : Model -> Bool
editingTagsTabFilledIn =
    .editingStory >> .tags >> List.isEmpty >> not


{-| Returns true if the new story is ready for publication.
-}
newStoryDataReadyForPublication : Model -> Bool
newStoryDataReadyForPublication newStoryData =
    nameTabFilledIn newStoryData && descriptionTabFilledIn newStoryData && tagsTabFilledIn newStoryData


{-| Returns true if the editing story data is ready to be saved.
-}
editingStoryDataReadyForSave : Model -> Bool
editingStoryDataReadyForSave newStoryData =
    editingNameTabFilledIn newStoryData
        && editingDescriptionTabFilledIn newStoryData
        && editingTagsTabFilledIn newStoryData
