module Pages.NewStory.View exposing (..)

import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Tags as Tags
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, defaultValue, hidden, id, placeholder)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.NewStory.Messages exposing (..)
import Pages.NewStory.Model exposing (..)


{-| The view for creating a new story.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    let
        currentRoute =
            shared.route

        editingStoryQueryParam =
            Route.getEditingStoryQueryParamOnCreateNewStoryRoute shared.route

        isEditingStory =
            Util.isNotNothing editingStoryQueryParam

        editingStoryLoaded =
            Just model.editingStory.id == editingStoryQueryParam
    in
    div
        [ class "new-story-page"
        , hidden <| isEditingStory && not editingStoryLoaded
        ]
        [ div
            [ class "sub-bar" ]
            (case editingStoryQueryParam of
                Nothing ->
                    [ button
                        [ class "sub-bar-button"
                        , onClick <| subMsg Reset
                        ]
                        [ text "Reset" ]
                    , button
                        [ classList
                            [ ( "continue-button", True )
                            , ( "publish-button", newStoryDataReadyForPublication model )
                            , ( "disabled-publish-button", not <| newStoryDataReadyForPublication model )
                            , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.PublishNewStory )
                            ]
                        , onClick <| subMsg Publish
                        ]
                        [ text "Proceed to Tidbit Selection" ]
                    ]

                Just storyID ->
                    [ button
                        [ class "sub-bar-button"
                        , onClick <| subMsg <| CancelEdits storyID
                        ]
                        [ text "Cancel" ]
                    , button
                        [ classList
                            [ ( "sub-bar-button save-changes", True )
                            , ( "publish-button", editingStoryDataReadyForSave model )
                            , ( "disabled-publish-button", not <| editingStoryDataReadyForSave model )
                            , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateStoryInfo )
                            ]
                        , onClick <| subMsg <| SaveEdits storyID
                        ]
                        [ text "Save Changes" ]
                    ]
            )
        , div
            [ class "create-tidbit-navbar" ]
            [ div
                [ classList
                    [ ( "create-tidbit-tab", True )
                    , ( "create-tidbit-selected-tab"
                      , case currentRoute of
                            Route.CreateStoryNamePage _ ->
                                True

                            _ ->
                                False
                      )
                    , ( "filled-in"
                      , if isEditingStory then
                            editingNameTabFilledIn model
                        else
                            nameTabFilledIn model
                      )
                    ]
                , onClick <|
                    BaseMessage.GoTo { wipeModalError = False } <|
                        Route.CreateStoryNamePage editingStoryQueryParam
                ]
                [ text "Name" ]
            , div
                [ classList
                    [ ( "create-tidbit-tab", True )
                    , ( "create-tidbit-selected-tab"
                      , case currentRoute of
                            Route.CreateStoryDescriptionPage _ ->
                                True

                            _ ->
                                False
                      )
                    , ( "filled-in"
                      , if isEditingStory then
                            editingDescriptionTabFilledIn model
                        else
                            descriptionTabFilledIn model
                      )
                    ]
                , onClick <|
                    BaseMessage.GoTo { wipeModalError = False } <|
                        Route.CreateStoryDescriptionPage editingStoryQueryParam
                ]
                [ text "Description" ]
            , div
                [ classList
                    [ ( "create-tidbit-tab", True )
                    , ( "create-tidbit-selected-tab"
                      , case currentRoute of
                            Route.CreateStoryTagsPage _ ->
                                True

                            _ ->
                                False
                      )
                    , ( "filled-in"
                      , if isEditingStory then
                            editingTagsTabFilledIn model
                        else
                            tagsTabFilledIn model
                      )
                    ]
                , onClick <|
                    BaseMessage.GoTo { wipeModalError = False } <|
                        Route.CreateStoryTagsPage editingStoryQueryParam
                ]
                [ text "Tags" ]
            ]
        , case currentRoute of
            Route.CreateStoryNamePage qpEditingStory ->
                div
                    [ class "create-new-story-name" ]
                    (case qpEditingStory of
                        Nothing ->
                            [ TextFields.input
                                shared.textFieldKeyTracker
                                "create-story-name"
                                [ placeholder "Name"
                                , id "name-input"
                                , onInput <| subMsg << OnUpdateName
                                , defaultValue model.newStory.name
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Tab then
                                            Just BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Util.limitCharsText 50 model.newStory.name
                            ]

                        _ ->
                            [ TextFields.input
                                shared.textFieldKeyTracker
                                "edit-story-name"
                                [ placeholder "Edit Story Name"
                                , id "name-input"
                                , onInput <| subMsg << OnEditingUpdateName
                                , defaultValue model.editingStory.name
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Tab then
                                            Just BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Util.limitCharsText 50 model.editingStory.name
                            ]
                    )

            Route.CreateStoryDescriptionPage qpEditingStory ->
                div
                    [ class "create-new-story-description" ]
                    (case qpEditingStory of
                        Nothing ->
                            [ TextFields.textarea
                                shared.textFieldKeyTracker
                                "create-story-description"
                                [ placeholder "Description"
                                , id "description-input"
                                , onInput <| subMsg << OnUpdateDescription
                                , defaultValue model.newStory.description
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Tab then
                                            Just BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Util.limitCharsText 300 model.newStory.description
                            ]

                        Just editingStory ->
                            [ TextFields.textarea
                                shared.textFieldKeyTracker
                                "edit-story-description"
                                [ placeholder "Edit Story Description"
                                , id "description-input"
                                , onInput <| subMsg << OnEditingUpdateDescription
                                , defaultValue model.editingStory.description
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Tab then
                                            Just BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Util.limitCharsText 300 model.editingStory.description
                            ]
                    )

            Route.CreateStoryTagsPage qpEditingStory ->
                div
                    [ class "create-new-story-tags" ]
                    (case qpEditingStory of
                        Nothing ->
                            [ TextFields.input
                                shared.textFieldKeyTracker
                                "create-story-tags"
                                [ placeholder "Tags"
                                , id "tags-input"
                                , onInput <| subMsg << OnUpdateTagInput
                                , defaultValue model.tagInput
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Enter || key == KK.Space then
                                            Just <| subMsg <| AddTag model.tagInput
                                        else if key == KK.Tab then
                                            Just <| BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Tags.view (subMsg << RemoveTag) model.newStory.tags
                            ]

                        Just _ ->
                            [ TextFields.input
                                shared.textFieldKeyTracker
                                "edit-story-tags"
                                [ placeholder "Edit Story Tags"
                                , id "tags-input"
                                , onInput <| subMsg << OnEditingUpdateTagInput
                                , defaultValue model.editingStoryTagInput
                                , Util.onKeydownPreventDefault
                                    (\key ->
                                        if key == KK.Enter || key == KK.Space then
                                            Just <| subMsg <| EditingAddTag model.editingStoryTagInput
                                        else if key == KK.Tab then
                                            Just <| BaseMessage.NoOp
                                        else
                                            Nothing
                                    )
                                ]
                            , Tags.view (subMsg << EditingRemoveTag) model.editingStory.tags
                            ]
                    )

            _ ->
                Util.hiddenDiv
        ]
