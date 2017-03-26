module Pages.NewStory.Update exposing (..)

import Api
import DefaultServices.Util as Util
import Models.Route as Route
import Models.Story as Story
import Pages.Model exposing (Shared)
import Pages.NewStory.Init exposing (..)
import Pages.NewStory.Messages exposing (..)
import Pages.NewStory.Model exposing (..)


{-| `NewStory` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                let
                    -- If the ID of the current editingStory is different, we
                    -- need to get the info of the story that we are editing.
                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    getEditingStoryAndFocusOn theID qpEditingStory =
                        justProduceCmd <|
                            Cmd.batch
                                [ Util.domFocus (\_ -> NoOp) theID
                                , case qpEditingStory of
                                    Nothing ->
                                        Cmd.none

                                    Just storyID ->
                                        -- We already loaded the story we want to edit.
                                        if storyID == model.editingStory.id then
                                            Cmd.none
                                        else
                                            Api.getStory
                                                storyID
                                                OnGetEditingStoryFailure
                                                OnGetEditingStorySuccess
                                ]
                in
                    case route of
                        Route.CreateStoryNamePage qpEditingStory ->
                            getEditingStoryAndFocusOn "name-input" qpEditingStory

                        Route.CreateStoryDescriptionPage qpEditingStory ->
                            getEditingStoryAndFocusOn "description-input" qpEditingStory

                        Route.CreateStoryTagsPage qpEditingStory ->
                            getEditingStoryAndFocusOn "tags-input" qpEditingStory

                        _ ->
                            doNothing

            OnGetEditingStorySuccess story ->
                case shared.user of
                    Nothing ->
                        doNothing

                    Just user ->
                        if story.author == user.id then
                            justUpdateModel <| updateEditStory <| always story
                        else
                            justProduceCmd <| Route.modifyTo <| Route.CreatePage

            OnGetEditingStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            OnUpdateName newName ->
                justUpdateModel <| updateName newName

            OnEditingUpdateName newName ->
                justUpdateModel <| updateEditName newName

            OnUpdateDescription newDescription ->
                justUpdateModel <| updateDescription newDescription

            OnEditingUpdateDescription newDescription ->
                justUpdateModel <| updateEditDescription newDescription

            OnUpdateTagInput newTagInput ->
                justUpdateModel <|
                    if String.endsWith " " newTagInput then
                        newTag <| String.dropRight 1 newTagInput
                    else
                        updateTagInput newTagInput

            OnEditingUpdateTagInput newTagInput ->
                justUpdateModel <|
                    if String.endsWith " " newTagInput then
                        newEditTag <| String.dropRight 1 newTagInput
                    else
                        updateEditTagInput newTagInput

            AddTag tagName ->
                justUpdateModel <| newTag tagName

            EditingAddTag tagName ->
                justUpdateModel <| newEditTag tagName

            RemoveTag tagName ->
                justUpdateModel <| removeTag tagName

            EditingRemoveTag tagName ->
                justUpdateModel <| removeEditTag tagName

            Reset ->
                ( init
                , shared
                  -- The reset button only exists when there is no `qpEditingStory`.
                , Route.navigateTo <| Route.CreateStoryNamePage Nothing
                )

            Publish ->
                if newStoryDataReadyForPublication model then
                    justProduceCmd <|
                        Api.postCreateNewStory
                            model.newStory
                            OnPublishFailure
                            OnPublishSuccess
                else
                    doNothing

            OnPublishSuccess { targetID } ->
                ( init
                , { shared | userStories = Nothing }
                , Route.navigateTo <| Route.DevelopStoryPage targetID
                )

            OnPublishFailure apiError ->
                -- TODO handle error.
                doNothing

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
                    justProduceCmd <|
                        Api.postUpdateStoryInformation
                            storyID
                            editingStoryInformation
                            OnSaveEditsFailure
                            OnSaveEditsSuccess

            OnSaveEditsSuccess { targetID } ->
                ( model
                , { shared | userStories = Nothing }
                , Route.navigateTo <| Route.DevelopStoryPage targetID
                )

            OnSaveEditsFailure apiError ->
                -- TODO handle error.
                doNothing
