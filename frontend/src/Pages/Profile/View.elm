module Pages.Profile.View exposing (..)

import DefaultServices.Editable exposing (bufferIs)
import DefaultServices.Util as Util
import Html exposing (Html, div, button, text, input, i, textarea)
import Html.Attributes exposing (class, classList, hidden, placeholder, value, disabled)
import Html.Events exposing (onClick, onInput)
import Models.RequestTracker as RT
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
                                [ classList
                                    [ ( "profile-card-sub-box-content", True )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateName )
                                    ]
                                , placeholder "Preferred name..."
                                , value <| getNameWithDefault model user.name
                                , onInput <| OnEditName user.name
                                , disabled <| RT.isMakingRequest shared.apiRequestTracker RT.UpdateName
                                ]
                                []
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| isEditingName model )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateName )
                                    ]
                                , onClick CancelEditedName
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
                                , onClick SaveEditedName
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
                                [ classList
                                    [ ( "profile-card-sub-box-content bio-textarea", True )
                                    , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio )
                                    ]
                                , placeholder "Tell everyone about yourself..."
                                , value <| getBioWithDefault model user.bio
                                , onInput <| OnEditBio user.bio
                                , disabled <| RT.isMakingRequest shared.apiRequestTracker RT.UpdateBio
                                ]
                                []
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
                                    , onClick CancelEditedBio
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
                                    , onClick SaveEditedBio
                                    ]
                                    [ text "check_circle" ]
                                ]
                            ]
                        , button
                            [ classList
                                [ ( "logout-button", True )
                                , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.Logout )
                                ]
                            , onClick LogOut
                            ]
                            [ text "Log Out" ]
                        , div
                            [ class "logout-error"
                            , hidden <| Util.isNothing model.logOutError
                            ]
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
