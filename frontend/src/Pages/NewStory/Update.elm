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
                                                NewStoryGetEditingStoryFailure
                                                NewStoryGetEditingStorySuccess
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

            NewStoryUpdateName newName ->
                justUpdateModel <| updateName newName

            NewStoryEditingUpdateName newName ->
                justUpdateModel <| updateEditName newName

            NewStoryUpdateDescription newDescription ->
                justUpdateModel <| updateDescription newDescription

            NewStoryEditingUpdateDescription newDescription ->
                justUpdateModel <| updateEditDescription newDescription

            NewStoryUpdateTagInput newTagInput ->
                justUpdateModel <|
                    if String.endsWith " " newTagInput then
                        newTag <|
                            String.dropRight 1 newTagInput
                    else
                        updateTagInput newTagInput

            NewStoryEditingUpdateTagInput newTagInput ->
                justUpdateModel <|
                    if String.endsWith " " newTagInput then
                        newEditTag <|
                            String.dropRight 1 newTagInput
                    else
                        updateEditTagInput newTagInput

            NewStoryAddTag tagName ->
                justUpdateModel <| newTag tagName

            NewStoryEditingAddTag tagName ->
                justUpdateModel <| newEditTag tagName

            NewStoryRemoveTag tagName ->
                justUpdateModel <| removeTag tagName

            NewStoryEditingRemoveTag tagName ->
                justUpdateModel <| removeEditTag tagName

            NewStoryReset ->
                ( init
                , shared
                  -- The reset button only exists when there is no `qpEditingStory`.
                , Route.navigateTo <| Route.CreateStoryNamePage Nothing
                )

            NewStoryPublish ->
                if newStoryDataReadyForPublication model then
                    justProduceCmd <|
                        Api.postCreateNewStory
                            model.newStory
                            NewStoryPublishFailure
                            NewStoryPublishSuccess
                else
                    doNothing

            NewStoryPublishFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStoryPublishSuccess { targetID } ->
                ( init
                , { shared
                    | userStories = Nothing
                  }
                , Route.navigateTo <| Route.DevelopStoryPage targetID
                )

            NewStoryGetEditingStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStoryGetEditingStorySuccess story ->
                case shared.user of
                    Nothing ->
                        doNothing

                    Just user ->
                        if story.author == user.id then
                            justUpdateModel <| updateEditStory <| always story
                        else
                            justProduceCmd <| Route.modifyTo <| Route.CreatePage

            NewStoryCancelEdits storyID ->
                ( updateEditStory (always Story.blankStory) model
                , shared
                , Route.navigateTo <| Route.DevelopStoryPage storyID
                )

            NewStorySaveEdits storyID ->
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
                            NewStorySaveEditsFailure
                            NewStorySaveEditsSuccess

            NewStorySaveEditsFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStorySaveEditsSuccess { targetID } ->
                ( model
                , { shared
                    | userStories = Nothing
                  }
                , Route.navigateTo <| Route.DevelopStoryPage targetID
                )
