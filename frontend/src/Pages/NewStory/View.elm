module Pages.NewStory.View exposing (..)

import DefaultServices.Util as Util
import Elements.Tags exposing (tags)
import Html exposing (Html, div, text, input, textarea, button)
import Html.Attributes exposing (class, classList, placeholder, value, id, hidden)
import Html.Events exposing (onClick, onInput)
import Pages.NewStory.Model exposing (..)
import Pages.NewStory.Messages exposing (..)
import Pages.Model exposing (Shared)
import Models.Route as Route
import Keyboard.Extra as KK


{-| The view for creating a new story.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        currentRoute =
            shared.route

        editingStoryQueryParam =
            Route.getEditingStoryQueryParamOnCreateNewStoryRoute shared.route

        isEditingStory =
            Util.isNotNothing editingStoryQueryParam

        editingStoryLoaded =
            (Just model.editingStory.id == editingStoryQueryParam)
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
                            , onClick NewStoryReset
                            ]
                            [ text "Reset" ]
                        , button
                            [ classList
                                [ ( "continue-button", True )
                                , ( "publish-button", newStoryDataReadyForPublication model )
                                , ( "disabled-publish-button", not <| newStoryDataReadyForPublication model )
                                ]
                            , onClick NewStoryPublish
                            ]
                            [ text "Proceed to Tidbit Selection" ]
                        ]

                    Just storyID ->
                        [ button
                            [ class "sub-bar-button"
                            , onClick <| NewStoryCancelEdits storyID
                            ]
                            [ text "Cancel" ]
                        , button
                            [ classList
                                [ ( "sub-bar-button save-changes", True )
                                , ( "publish-button", editingStoryDataReadyForSave model )
                                , ( "disabled-publish-button", not <| editingStoryDataReadyForSave model )
                                ]
                            , onClick <| NewStorySaveEdits storyID
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
                    , onClick <| GoTo <| Route.CreateStoryNamePage editingStoryQueryParam
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
                    , onClick <| GoTo <| Route.CreateStoryDescriptionPage editingStoryQueryParam
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
                    , onClick <| GoTo <| Route.CreateStoryTagsPage editingStoryQueryParam
                    ]
                    [ text "Tags" ]
                ]
            , case currentRoute of
                Route.CreateStoryNamePage qpEditingStory ->
                    div
                        [ class "create-new-story-name" ]
                        [ case qpEditingStory of
                            Nothing ->
                                input
                                    [ placeholder "Name"
                                    , id "name-input"
                                    , onInput NewStoryUpdateName
                                    , value model.newStory.name
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []

                            _ ->
                                input
                                    [ placeholder "Edit Story Name"
                                    , id "name-input"
                                    , onInput NewStoryEditingUpdateName
                                    , value model.editingStory.name
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                        ]

                Route.CreateStoryDescriptionPage qpEditingStory ->
                    div
                        [ class "create-new-story-description" ]
                        [ case qpEditingStory of
                            Nothing ->
                                textarea
                                    [ placeholder "Description"
                                    , id "description-input"
                                    , onInput NewStoryUpdateDescription
                                    , value model.newStory.description
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []

                            Just editingStory ->
                                textarea
                                    [ placeholder "Edit Story Description"
                                    , id "description-input"
                                    , onInput NewStoryEditingUpdateDescription
                                    , value model.editingStory.description
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                        ]

                Route.CreateStoryTagsPage qpEditingStory ->
                    div
                        [ class "create-new-story-tags" ]
                        (case qpEditingStory of
                            Nothing ->
                                [ input
                                    [ placeholder "Tags"
                                    , id "tags-input"
                                    , onInput NewStoryUpdateTagInput
                                    , value model.tagInput
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Enter then
                                                Just <| NewStoryAddTag model.tagInput
                                            else if key == KK.Tab then
                                                Just <| NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                                , tags
                                    NewStoryRemoveTag
                                    model.newStory.tags
                                ]

                            Just _ ->
                                [ input
                                    [ placeholder "Edit Story Tags"
                                    , id "tags-input"
                                    , onInput NewStoryEditingUpdateTagInput
                                    , value model.editingStoryTagInput
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Enter then
                                                Just <|
                                                    NewStoryEditingAddTag model.editingStoryTagInput
                                            else if key == KK.Tab then
                                                Just <| NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                                , tags
                                    NewStoryEditingRemoveTag
                                    model.editingStory.tags
                                ]
                        )

                _ ->
                    Util.hiddenDiv
            ]
