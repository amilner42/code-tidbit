module Api exposing (API, api)

import Date
import DefaultServices.Http as HttpService
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import JSON.BasicResponse
import JSON.Bigbit
import JSON.Completed
import JSON.Content
import JSON.ContentPointer
import JSON.IDResponse
import JSON.Opinion
import JSON.QA
import JSON.Range
import JSON.Rating
import JSON.Snipbit
import JSON.Story
import JSON.Tidbit
import JSON.TidbitPointer
import JSON.User
import JSON.Vote
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Content as Content
import Models.ContentPointer as ContentPointer
import Models.IDResponse as IDResponse
import Models.Opinion as Opinion
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.Vote as Vote
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import ProjectTypeAliases exposing (..)


{-| An endpoint is the gateway to communicating with the API.

It will either error/succeed and requires handlers for both situations. The types parameters of the endpoint let you
know what the endpoint returns.

-}
type alias Endpoint response msg =
    (ApiError.ApiError -> msg) -> (response -> msg) -> Cmd msg


{-| The API to access the backend.
-}
type alias API msg =
    { get :
        { -- Gets the users account, or an error if unauthenticated.
          account : Endpoint User.User msg

        -- Gets stories, you can use query params to customize the search. Refer to the backend to see the options.
        , stories : QueryParams -> Endpoint ( Bool, List Story.Story ) msg

        -- Gets a single story.
        , story : StoryID -> Endpoint Story.Story msg

        -- Gets a single expanded story.
        , expandedStory : StoryID -> Endpoint Story.ExpandedStory msg

        -- Gets a single expanded story with the completed list attached.
        , expandedStoryWithCompleted : StoryID -> Endpoint Story.ExpandedStory msg

        -- Queries the API to log the user out, which should send a response to delete the cookies.
        , logOut : Endpoint BasicResponse.BasicResponse msg

        -- Get's a snipbit.
        , snipbit : SnipbitID -> Endpoint Snipbit.Snipbit msg

        -- Get's a bigbit.
        , bigbit : BigbitID -> Endpoint Bigbit.Bigbit msg

        -- Gets tidbits, you can use query params to customize the search. Refer to the backend to see the options.
        , tidbits : QueryParams -> Endpoint ( Bool, List Tidbit.Tidbit ) msg

        -- Get's content, you can use query params to customize the search. Refer to the backend to see the options.
        , content : QueryParams -> Endpoint ( Bool, List Content.Content ) msg

        -- Get's a user's opinion.
        , opinion : ContentPointer.ContentPointer -> Endpoint (Maybe Rating.Rating) msg

        -- Get's the QA object for a specific snipbit.
        , snipbitQA : SnipbitID -> Endpoint QA.SnipbitQA msg

        -- Get's the QA object for a specific bigbit.
        , bigbitQA : BigbitID -> Endpoint QA.BigbitQA msg
        }
    , post :
        { -- Logs user in and returns the user, unless invalid credentials.
          login : User.UserForLogin -> Endpoint User.User msg

        -- Registers the user and returns the user, unless invalid new credentials.
        , register : User.UserForRegistration -> Endpoint User.User msg

        -- Gets the ID of the user that exists with that email (if one exists, otherwise returns `Nothing`).
        , userExists : Email -> Endpoint (Maybe UserID) msg

        -- Creates a new snipbit.
        , createSnipbit : CreateSnipbitModel.SnipbitForPublication -> Endpoint IDResponse.IDResponse msg

        -- Creates a new bigbit.
        , createBigbit : CreateBigbitModel.BigbitForPublication -> Endpoint IDResponse.IDResponse msg

        -- Updates a user.
        , updateUser : User.UserUpdateRecord -> Endpoint User.User msg

        -- Creates a new story.
        , createNewStory : Story.NewStory -> Endpoint IDResponse.IDResponse msg

        -- Updates the information for a story.
        , updateStoryInformation : StoryID -> Story.NewStory -> Endpoint IDResponse.IDResponse msg

        -- Updates a story with new tidbits.
        , addTidbitsToStory : StoryID -> List TidbitPointer.TidbitPointer -> Endpoint Story.ExpandedStory msg

        -- Adds a new `Completed` to the list of things the user has completed.
        , addCompleted : Completed.Completed -> Endpoint Bool msg

        -- Removes a `Completed` from the users list of completed tidbits.
        , removeCompleted : Completed.Completed -> Endpoint Bool msg

        -- Checks if something is completed, does not modify the db.
        , checkCompleted : Completed.Completed -> Endpoint Bool msg

        -- Adds an opinion for a logged-in user.
        , addOpinion : Opinion.Opinion -> Endpoint Bool msg

        -- Removes an opinion for a logged-in user.
        , removeOpinion : Opinion.Opinion -> Endpoint Bool msg

        -- Ask a question on a snipbit.
        , askQuestionOnSnipbit : SnipbitID -> QuestionText -> Range.Range -> Endpoint (QA.Question Range.Range) msg

        -- Ask a question on a bigbit.
        , askQuestionOnBigbit : BigbitID -> QuestionText -> QA.BigbitCodePointer -> Endpoint (QA.Question QA.BigbitCodePointer) msg

        -- Edit a question on a snipbit.
        , editQuestionOnSnipbit : SnipbitID -> QuestionID -> QuestionText -> Range.Range -> Endpoint Date.Date msg

        -- Edit a question on a bigbit.
        , editQuestionOnBigbit : BigbitID -> QuestionID -> QuestionText -> QA.BigbitCodePointer -> Endpoint Date.Date msg

        -- Deletes a question.
        , deleteQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Endpoint () msg

        -- Place your vote (`Vote`) on a question.
        , rateQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Vote.Vote -> Endpoint () msg

        -- Remove a rating from a question.
        , removeQuestionRating : TidbitPointer.TidbitPointer -> QuestionID -> Endpoint () msg

        -- Sets the pin-state of a question.
        , pinQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Bool -> Endpoint () msg

        -- Answer a question.
        , answerQuestion : TidbitPointer.TidbitPointer -> QuestionID -> AnswerText -> Endpoint QA.Answer msg

        -- Edit an answer.
        , editAnswer : TidbitPointer.TidbitPointer -> AnswerID -> AnswerText -> Endpoint Date.Date msg

        -- Deletes an answer.
        , deleteAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Endpoint () msg

        -- Rates an answer.
        , rateAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Vote.Vote -> Endpoint () msg

        -- Removes a rating from an answer.
        , removeAnswerRating : TidbitPointer.TidbitPointer -> AnswerID -> Endpoint () msg

        -- Sets the pin-state of an answer.
        , pinAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Bool -> Endpoint () msg

        -- Comment on a question (adds to the existing comment thread).
        , commentOnQuestion : TidbitPointer.TidbitPointer -> QuestionID -> CommentText -> Endpoint QA.QuestionComment msg

        -- Edit a comment on a question.
        , editQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> Endpoint Date.Date msg

        -- Delete a comment on a question.
        , deleteQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> Endpoint () msg

        -- Comment on an answer.
        , commentOnAnswer : TidbitPointer.TidbitPointer -> QuestionID -> AnswerID -> CommentText -> Endpoint QA.AnswerComment msg

        -- Edit a comment on an answer.
        , editAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> Endpoint Date.Date msg

        -- Delete a comment on an answer.
        , deleteAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> Endpoint () msg
        }
    }


{-| The access point to the API.

Currently takes the API base url as configuration (different in prod and dev).

-}
api : String -> API msg
api apiBaseUrl =
    let
        {- Helper for querying the API (GET), automatically adds the apiBaseUrl prefix. -}
        makeGETEndpoint : String -> Decode.Decoder response -> Endpoint response msg
        makeGETEndpoint url =
            HttpService.get (apiBaseUrl ++ url)

        {- Helper for qeurying the API (POST), automatically adds the apiBaseUrl prefix. -}
        makePOSTEndpoint : String -> Decode.Decoder response -> Encode.Value -> Endpoint response msg
        makePOSTEndpoint url =
            HttpService.post (apiBaseUrl ++ url)
    in
    { get =
        { account =
            makeGETEndpoint "account" JSON.User.decoder
        , stories =
            \queryParams ->
                makeGETEndpoint
                    ("stories" ++ Util.queryParamsToString queryParams)
                    (Util.decodePair Decode.bool (Decode.list <| JSON.Story.decoder))
        , story =
            \storyID -> makeGETEndpoint ("stories" :/: storyID) JSON.Story.decoder
        , expandedStory =
            \storyID ->
                makeGETEndpoint
                    ("stories" :/: storyID ++ Util.queryParamsToString [ ( "expandStory", Just "true" ) ])
                    JSON.Story.expandedStoryDecoder
        , expandedStoryWithCompleted =
            \storyID ->
                makeGETEndpoint
                    ("stories"
                        :/: storyID
                        ++ Util.queryParamsToString
                            [ ( "expandStory", Just "true" )
                            , ( "withCompleted", Just "true" )
                            ]
                    )
                    JSON.Story.expandedStoryDecoder
        , logOut =
            makeGETEndpoint "logOut" JSON.BasicResponse.decoder
        , snipbit =
            \snipbitID -> makeGETEndpoint ("snipbits" :/: snipbitID) JSON.Snipbit.decoder
        , bigbit =
            \bigbitID -> makeGETEndpoint ("bigbits" :/: bigbitID) JSON.Bigbit.decoder
        , tidbits =
            \queryParams ->
                makeGETEndpoint
                    ("tidbits" ++ Util.queryParamsToString queryParams)
                    (Util.decodePair Decode.bool (Decode.list JSON.Tidbit.decoder))
        , content =
            \queryParams ->
                makeGETEndpoint
                    ("content" ++ Util.queryParamsToString queryParams)
                    (Util.decodePair Decode.bool (Decode.list JSON.Content.decoder))
        , opinion =
            \contentPointer ->
                makeGETEndpoint
                    ("account/getOpinion"
                        :/: (toString <| JSON.ContentPointer.contentTypeToInt contentPointer.contentType)
                        :/: contentPointer.contentID
                    )
                    (Decode.maybe JSON.Rating.decoder)
        , snipbitQA =
            \snipbitID ->
                makeGETEndpoint
                    ("qa" :/: tidbitPointerToUrl { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID })
                    JSON.QA.snipbitQADecoder
        , bigbitQA =
            \bigbitID ->
                makeGETEndpoint
                    ("qa" :/: tidbitPointerToUrl { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID })
                    JSON.QA.bigbitQADecoder
        }
    , post =
        { login =
            \user -> makePOSTEndpoint "login" JSON.User.decoder (JSON.User.loginEncoder user)
        , register =
            \user -> makePOSTEndpoint "register" JSON.User.decoder (JSON.User.registerEncoder user)
        , userExists =
            \email ->
                makePOSTEndpoint
                    "userID"
                    (Decode.maybe Decode.string)
                    (Encode.object [ ( "email", Encode.string email ) ])
        , createSnipbit =
            \snipbit ->
                makePOSTEndpoint
                    "snipbits"
                    JSON.IDResponse.decoder
                    (CreateSnipbitJSON.publicationEncoder snipbit)
        , createBigbit =
            \bigbit ->
                makePOSTEndpoint
                    "bigbits"
                    JSON.IDResponse.decoder
                    (CreateBigbitJSON.publicationEncoder bigbit)
        , updateUser =
            \updateRecord ->
                makePOSTEndpoint
                    "account"
                    JSON.User.decoder
                    (JSON.User.updateRecordEncoder updateRecord)
        , createNewStory =
            \newStory ->
                makePOSTEndpoint
                    "stories"
                    JSON.IDResponse.decoder
                    (JSON.Story.newStoryEncoder newStory)
        , updateStoryInformation =
            \storyID newStoryInformation ->
                makePOSTEndpoint
                    ("stories" :/: storyID :/: "information")
                    JSON.IDResponse.decoder
                    (JSON.Story.newStoryEncoder newStoryInformation)
        , addTidbitsToStory =
            \storyID newTidbitPointers ->
                makePOSTEndpoint
                    ("stories" :/: storyID :/: "addTidbits")
                    JSON.Story.expandedStoryDecoder
                    (Encode.list <| List.map JSON.TidbitPointer.encoder newTidbitPointers)
        , addCompleted =
            \completed ->
                makePOSTEndpoint
                    "account/addCompleted"
                    Decode.bool
                    (JSON.Completed.encoder completed)
        , removeCompleted =
            \completed ->
                makePOSTEndpoint
                    "account/removeCompleted"
                    Decode.bool
                    (JSON.Completed.encoder completed)
        , checkCompleted =
            \completed ->
                makePOSTEndpoint
                    "account/checkCompleted"
                    Decode.bool
                    (JSON.Completed.encoder completed)
        , addOpinion =
            \opinion ->
                makePOSTEndpoint
                    "account/addOpinion"
                    Decode.bool
                    (JSON.Opinion.encoder opinion)
        , removeOpinion =
            \opinion ->
                makePOSTEndpoint
                    "account/removeOpinion"
                    Decode.bool
                    (JSON.Opinion.encoder opinion)
        , askQuestionOnSnipbit =
            \snipbitID questionText codePointer ->
                makePOSTEndpoint
                    ("qa/1" :/: snipbitID :/: "askQuestion")
                    (JSON.QA.questionDecoder JSON.Range.decoder)
                    (Encode.object
                        [ ( "questionText", Encode.string questionText )
                        , ( "codePointer", JSON.Range.encoder codePointer )
                        ]
                    )
        , askQuestionOnBigbit =
            \bigbitID questionText codePointer ->
                makePOSTEndpoint
                    ("qa/2" :/: bigbitID :/: "askQuestion")
                    (JSON.QA.questionDecoder JSON.QA.bigbitCodePointerDecoder)
                    (Encode.object
                        [ ( "questionText", Encode.string questionText )
                        , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                        ]
                    )
        , editQuestionOnSnipbit =
            \snipbitID questionID questionText codePointer ->
                makePOSTEndpoint
                    ("qa/1" :/: snipbitID :/: "editQuestion")
                    Util.dateDecoder
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "questionText", Encode.string questionText )
                        , ( "codePointer", JSON.Range.encoder codePointer )
                        ]
                    )
        , editQuestionOnBigbit =
            \bigbitID questionID questionText codePointer ->
                makePOSTEndpoint
                    ("qa/2" :/: bigbitID :/: "editQuestion")
                    Util.dateDecoder
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "questionText", Encode.string questionText )
                        , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                        ]
                    )
        , deleteQuestion =
            \tidbitPointer questionID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "deleteQuestion")
                    (decode ())
                    (Encode.object [ ( "questionID", Encode.string questionID ) ])
        , rateQuestion =
            \tidbitPointer questionID vote ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "rateQuestion")
                    (decode ())
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "vote", JSON.Vote.encoder vote )
                        ]
                    )
        , removeQuestionRating =
            \tidbitPointer questionID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "removeQuestionRating")
                    (decode ())
                    (Encode.object [ ( "questionID", Encode.string questionID ) ])
        , pinQuestion =
            \tidbitPointer questionID pin ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "pinQuestion")
                    (decode ())
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "pin", Encode.bool pin )
                        ]
                    )
        , answerQuestion =
            \tidbitPointer questionID answerText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "answerQuestion")
                    JSON.QA.answerDecoder
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "answerText", Encode.string answerText )
                        ]
                    )
        , editAnswer =
            \tidbitPointer answerID answerText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "editAnswer")
                    Util.dateDecoder
                    (Encode.object
                        [ ( "answerID", Encode.string answerID )
                        , ( "answerText", Encode.string answerText )
                        ]
                    )
        , deleteAnswer =
            \tidbitPointer answerID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "deleteAnswer")
                    (decode ())
                    (Encode.object [ ( "answerID", Encode.string answerID ) ])
        , rateAnswer =
            \tidbitPointer answerID vote ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "rateAnswer")
                    (decode ())
                    (Encode.object
                        [ ( "answerID", Encode.string answerID )
                        , ( "vote", JSON.Vote.encoder vote )
                        ]
                    )
        , removeAnswerRating =
            \tidbitPointer answerID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "removeAnswerRating")
                    (decode ())
                    (Encode.object [ ( "answerID", Encode.string answerID ) ])
        , pinAnswer =
            \tidbitPointer answerID pin ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "pinAnswer")
                    (decode ())
                    (Encode.object
                        [ ( "answerID", Encode.string answerID )
                        , ( "pin", Encode.bool pin )
                        ]
                    )
        , commentOnQuestion =
            \tidbitPointer questionID commentText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "comment/question")
                    JSON.QA.questionCommentDecoder
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "commentText", Encode.string commentText )
                        ]
                    )
        , editQuestionComment =
            \tidbitPointer commentID commentText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "editComment/question")
                    Util.dateDecoder
                    (Encode.object
                        [ ( "commentText", Encode.string commentText )
                        , ( "commentID", Encode.string commentID )
                        ]
                    )
        , deleteQuestionComment =
            \tidbitPointer commentID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "deleteComment/question")
                    (decode ())
                    (Encode.object [ ( "commentID", Encode.string commentID ) ])
        , commentOnAnswer =
            \tidbitPointer questionID answerID commentText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "comment/answer")
                    JSON.QA.answerCommentDecoder
                    (Encode.object
                        [ ( "questionID", Encode.string questionID )
                        , ( "answerID", Encode.string answerID )
                        , ( "commentText", Encode.string commentText )
                        ]
                    )
        , editAnswerComment =
            \tidbitPointer commentID commentText ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "editComment/answer")
                    Util.dateDecoder
                    (Encode.object
                        [ ( "commentID", Encode.string commentID )
                        , ( "commentText", Encode.string commentText )
                        ]
                    )
        , deleteAnswerComment =
            \tidbitPointer commentID ->
                makePOSTEndpoint
                    ("qa" :/: tidbitPointerToUrl tidbitPointer :/: "deleteComment/answer")
                    (decode ())
                    (Encode.object [ ( "commentID", Encode.string commentID ) ])
        }
    }


{-| Converts tidbit pointers to the standard URL format: "<tidbitTypeToInt>/<tidbitID>"
-}
tidbitPointerToUrl : TidbitPointer.TidbitPointer -> String
tidbitPointerToUrl { tidbitType, targetID } =
    (toString <| JSON.TidbitPointer.tidbitTypeToInt tidbitType) :/: targetID
