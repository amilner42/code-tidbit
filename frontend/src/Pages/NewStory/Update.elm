module Pages.NewStory.Update exposing (..)

import Api exposing (api)
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Story as Story
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.NewStory.Init exposing (..)
import Pages.NewStory.Messages exposing (..)
import Pages.NewStory.Model exposing (..)


{-| `NewStory` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        OnRouteHit route ->
            let
                getEditingStoryAndFocusOn theID qpEditingStory =
                    case qpEditingStory of
                        Nothing ->
                            common.justProduceCmd <| Util.domFocus (\_ -> BaseMessage.NoOp) theID

                        Just storyID ->
                            {- If we already loaded the story we want to edit, we don't re-query because it
                               doesn't even matter if the story was updated, there isn't even a "reset" to
                               current. If we eventually make it an editable then we will probably want to
                               re-query and replace the original of the editable, while still keep the users
                               current edits.
                            -}
                            if storyID == model.editingStory.id then
                                common.justProduceCmd <| Util.domFocus (\_ -> BaseMessage.NoOp) theID
                            else
                                ( { model | editingStory = Story.blankStory }
                                , shared
                                , Cmd.batch
                                    [ Util.domFocus (\_ -> BaseMessage.NoOp) theID
                                    , api.get.story storyID
                                        (common.subMsg << OnGetEditingStoryFailure)
                                        (common.subMsg << OnGetEditingStorySuccess)
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
            common.justUpdateModel <| updateTagInput newTagInput

        OnEditingUpdateTagInput newTagInput ->
            common.justUpdateModel <| updateEditTagInput newTagInput

        AddTag tagName ->
            ( newTag tagName model
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-story-tags" }
            , Util.domFocus (always BaseMessage.NoOp) "tags-input"
            )

        EditingAddTag tagName ->
            ( newEditTag tagName model
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "edit-story-tags" }
            , Util.domFocus (always BaseMessage.NoOp) "tags-input"
            )

        RemoveTag tagName ->
            common.justUpdateModel <| removeTag tagName

        EditingRemoveTag tagName ->
            common.justUpdateModel <| removeEditTag tagName

        -- The reset button only exists when there is no `qpEditingStory`.
        Reset ->
            ( init
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-story-name" }
            , Route.navigateTo <| Route.CreateStoryNamePage Nothing
            )

        Publish ->
            let
                publishAction =
                    common.justProduceCmd <|
                        api.post.createNewStory
                            model.newStory
                            (common.subMsg << OnPublishFailure)
                            (common.subMsg << OnPublishSuccess)
            in
            if newStoryDataReadyForPublication model then
                common.makeSingletonRequest RT.PublishNewStory publishAction
            else
                common.doNothing

        OnPublishSuccess { targetID } ->
            ( init
            , { shared | userStories = Nothing }
            , Route.navigateTo <| Route.DevelopStoryPage targetID
            )
                |> common.andFinishRequest RT.PublishNewStory

        OnPublishFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.PublishNewStory

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

                saveEditsAction =
                    common.justProduceCmd <|
                        api.post.updateStoryInformation
                            storyID
                            editingStoryInformation
                            (common.subMsg << OnSaveEditsFailure)
                            (common.subMsg << OnSaveEditsSuccess)
            in
            if editingStoryDataReadyForSave model then
                common.makeSingletonRequest RT.UpdateStoryInfo saveEditsAction
            else
                common.doNothing

        OnSaveEditsSuccess { targetID } ->
            ( model
            , { shared | userStories = Nothing }
            , Route.navigateTo <| Route.DevelopStoryPage targetID
            )
                |> common.andFinishRequest RT.UpdateStoryInfo

        OnSaveEditsFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.UpdateStoryInfo
