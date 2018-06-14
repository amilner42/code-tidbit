module Pages.Profile.View exposing (..)

import DefaultServices.Editable exposing (bufferIs)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Html exposing (Html, button, div, i, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, hidden, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.RequestTracker as RT
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    case shared.user of
        Nothing ->
            Util.hiddenDiv

        Just user ->
            div [ class "profile-page" ]
                [ div
                    [ class "profile-panel" ]
                    [ div
                        [ class "profile-card account-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "Account" ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Email" ]
                            , div [ class "profile-card-sub-box-gap" ] []
                            , div
                                [ class "profile-card-sub-box-content email-display" ]
                                [ text user.email ]
                            ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Name" ]
                            , div [ class "profile-card-sub-box-gap" ] []
                            , TextFields.input
                                shared.textFieldKeyTracker
                                "profile-account-name"
                                [ classList
                                    [ ( "profile-card-sub-box-content", True )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateName )
                                    ]
                                , placeholder "Preferred name..."
                                , defaultValue <| getNameWithDefault model user.name
                                , onInput <| subMsg << OnEditName user.name
                                , disabled <| RT.isMakingRequest shared.apiRequestTracker RT.UpdateName
                                ]
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| isEditingName model )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateName )
                                    ]
                                , onClick <| subMsg CancelEditedName
                                ]
                                [ text "cancel" ]
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| isEditingName model )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateName )
                                    , ( "disabled"
                                      , Util.maybeMapWithDefault
                                            (bufferIs String.isEmpty)
                                            False
                                            model.accountName
                                      )
                                    ]
                                , onClick <| subMsg SaveEditedName
                                ]
                                [ text "check_circle" ]
                            ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Bio" ]
                            , div
                                [ class "profile-card-sub-box-gap" ]
                                []
                            , TextFields.textarea
                                shared.textFieldKeyTracker
                                "profile-account-bio"
                                [ classList
                                    [ ( "profile-card-sub-box-content bio-textarea", True )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio )
                                    ]
                                , placeholder "Tell everyone about yourself..."
                                , defaultValue <| getBioWithDefault model user.bio
                                , onInput <| subMsg << OnEditBio user.bio
                                , disabled <| RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio
                                ]
                            , div
                                [ class "bio-icons-box" ]
                                [ i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| isEditingBio model )
                                        , ( "cursor-progress"
                                          , RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio
                                          )
                                        ]
                                    , onClick <| subMsg CancelEditedBio
                                    ]
                                    [ text "cancel" ]
                                , i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| isEditingBio model )
                                        , ( "disabled"
                                          , Util.maybeMapWithDefault
                                                (bufferIs String.isEmpty)
                                                False
                                                model.accountBio
                                          )
                                        , ( "cursor-progress"
                                          , RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio
                                          )
                                        ]
                                    , onClick <| subMsg SaveEditedBio
                                    ]
                                    [ text "check_circle" ]
                                ]
                            ]
                        , button
                            [ classList
                                [ ( "logout-button", True )
                                , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.Logout )
                                ]
                            , onClick BaseMessage.LogOut
                            ]
                            [ text "Log Out" ]
                        , div
                            [ classList
                                [ ( "logout-error", True )
                                , ( "hidden", Util.isNothing shared.logoutError )
                                ]
                            ]
                            [ text "Cannot log out right now, try again shortly." ]
                        ]
                    , div
                        [ class "profile-card editor-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "Editor" ]
                        , div
                            [ class "coming-soon" ]
                            [ text "coming soon" ]
                        ]
                    , div
                        [ class "profile-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "App" ]
                        , div
                            [ class "coming-soon" ]
                            [ text "coming soon" ]
                        ]
                    ]
                ]
