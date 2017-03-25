module Pages.Profile.View exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, button, text, input, i, textarea)
import Html.Attributes exposing (class, classList, hidden, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
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
                            , input
                                [ class "profile-card-sub-box-content"
                                , placeholder "Preferred Name"
                                , value <| getNameWithDefault model user.name
                                , onInput <| ProfileUpdateName user.name
                                ]
                                []
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| isEditingName model )
                                    ]
                                , onClick ProfileCancelEditName
                                ]
                                [ text "cancel" ]
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| isEditingName model )
                                    ]
                                , onClick ProfileSaveEditName
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
                            , textarea
                                [ class "profile-card-sub-box-content bio-textarea"
                                , placeholder "Tell everyone about yourself..."
                                , value <| getBioWithDefault model user.bio
                                , onInput <| ProfileUpdateBio user.bio
                                ]
                                []
                            , div
                                [ class "bio-icons-box" ]
                                [ i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| isEditingBio model )
                                        ]
                                    , onClick ProfileCancelEditBio
                                    ]
                                    [ text "cancel" ]
                                , i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| isEditingBio model )
                                        ]
                                    , onClick ProfileSaveEditBio
                                    ]
                                    [ text "check_circle" ]
                                ]
                            ]
                        , button
                            [ class "logout-button"
                            , onClick LogOut
                            ]
                            [ text "Log Out" ]
                        , div
                            [ hidden <| Util.isNothing model.logOutError ]
                            [ text "Cannot log out right now, try again shortly." ]
                        ]
                    , div
                        [ class "profile-card editor-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "Editor" ]
                        ]
                    , div
                        [ class "profile-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "App" ]
                        ]
                    ]
                ]
