module Pages.NewStory.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util
import Models.Route as Route
import Models.Story as Story
import Pages.Model exposing (Shared)
import Pages.NewStory.Init exposing (..)
import Pages.NewStory.Messages exposing (..)
import Pages.NewStory.Model exposing (..)


{-| `NewStory` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            let
                getEditingStoryAndFocusOn theID qpEditingStory =
                    case qpEditingStory of
                        Nothing ->
                            common.justProduceCmd <| Util.domFocus (\_ -> NoOp) theID

                        Just storyID ->
                            {- If we already loaded the story we want to edit, we don't re-query because it
                               doesn't even matter if the story was updated, there isn't even a "reset" to
                               current. If we eventually make it an editable then we will probably want to
                               re-query and replace the original of the editable, while still keep the users
                               current edits.
                            -}
                            if storyID == model.editingStory.id then
                                common.justProduceCmd <| Util.domFocus (\_ -> NoOp) theID
                            else
                                ( { model | editingStory = Story.blankStory }
                                , shared
                                , Cmd.batch
                                    [ Util.domFocus (\_ -> NoOp) theID
                                    , common.api.get.story storyID OnGetEditingStoryFailure OnGetEditingStorySuccess
                                    ]
                                )
            in
                case route of
                    Route.CreateStoryNamePage qpEditingStory ->
                        getEditingStoryAndFocusOn "name-input" qpEditingStory

                    Route.CreateStoryDescriptionPage qpEditingStory ->
                        getEditingStoryAndFocusOn "description-input" qpEditingStory

                    Route.CreateStoryTagsPage qpEditingStory ->
                        getEditingStoryAndFocusOn "tags-input" qpEditingStory

                    _ ->
                        common.doNothing

        OnGetEditingStorySuccess story ->
            case shared.user of
                Nothing ->
                    common.doNothing

                Just user ->
                    if story.author == user.id then
                        common.justUpdateModel <| updateEditStory <| always story
                    else
                        common.justProduceCmd <| Route.modifyTo <| Route.CreatePage

        OnGetEditingStoryFailure apiError ->
            common.justSetModalError apiError

        OnUpdateName newName ->
            common.justUpdateModel <| updateName newName

        OnEditingUpdateName newName ->
            common.justUpdateModel <| updateEditName newName

        OnUpdateDescription newDescription ->
            common.justUpdateModel <| updateDescription newDescription

        OnEditingUpdateDescription newDescription ->
            common.justUpdateModel <| updateEditDescription newDescription

        OnUpdateTagInput newTagInput ->
            common.justUpdateModel <|
                if String.endsWith " " newTagInput then
                    newTag <| String.dropRight 1 newTagInput
                else
                    updateTagInput newTagInput

        OnEditingUpdateTagInput newTagInput ->
            common.justUpdateModel <|
                if String.endsWith " " newTagInput then
                    newEditTag <| String.dropRight 1 newTagInput
                else
                    updateEditTagInput newTagInput

        AddTag tagName ->
            common.justUpdateModel <| newTag tagName

        EditingAddTag tagName ->
            common.justUpdateModel <| newEditTag tagName

        RemoveTag tagName ->
            common.justUpdateModel <| removeTag tagName

        EditingRemoveTag tagName ->
            common.justUpdateModel <| removeEditTag tagName

        Reset ->
            ( init
            , shared
              -- The reset button only exists when there is no `qpEditingStory`.
            , Route.navigateTo <| Route.CreateStoryNamePage Nothing
            )

        Publish ->
            if newStoryDataReadyForPublication model then
                common.justProduceCmd <|
                    common.api.post.createNewStory
                        model.newStory
                        OnPublishFailure
                        OnPublishSuccess
            else
                common.doNothing

        OnPublishSuccess { targetID } ->
            ( init
            , { shared | userStories = Nothing }
            , Route.navigateTo <| Route.DevelopStoryPage targetID
            )

        OnPublishFailure apiError ->
            common.justSetModalError apiError

        CancelEdits storyID ->
            ( updateEditStory (always Story.blankStory) model
            , shared
            , Route.navigateTo <| Route.DevelopStoryPage storyID
            )

        SaveEdits storyID ->
            let
                editingStory =
                    model.editingStory

                editingStoryInformation =
                    { name = editingStory.name
                    , description = editingStory.description
                    , tags = editingStory.tags
                    }
            in
                if editingStoryDataReadyForSave model then
                    common.justProduceCmd <|
                        common.api.post.updateStoryInformation
                            storyID
                            editingStoryInformation
                            OnSaveEditsFailure
                            OnSaveEditsSuccess
                else
                    common.doNothing

        OnSaveEditsSuccess { targetID } ->
            ( model
            , { shared | userStories = Nothing }
            , Route.navigateTo <| Route.DevelopStoryPage targetID
            )

        OnSaveEditsFailure apiError ->
            common.justSetModalError apiError
