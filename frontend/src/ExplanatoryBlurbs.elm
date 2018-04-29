module ExplanatoryBlurbs exposing (..)

{-| Explanatory text that is exposed to the user, kept in one module so we can keep the "voice" of the website
consistent.
-}


{-| Used in `AnswerQuestion`.
-}
answerQuestionPlaceholder : String
answerQuestionPlaceholder =
    "Write your answer...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `EditAnswer`.
-}
editAnswerPlaceholder : String
editAnswerPlaceholder =
    "Edit your answer...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `EditQuestion`.
-}
editQuestionPlaceholder : String
editQuestionPlaceholder =
    "Edit your question...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `AskQuestion`.
-}
askQuestionPlaceholder : String
askQuestionPlaceholder =
    "Highlight the code confusing you and ask your question...\n\n\n"
        ++ markdownExplanatoryText


{-| Currently used in Snipbits/Bigbits to explain how to use markdown in the frame placeholders.
-}
markdownFramePlaceholder : Int -> String
markdownFramePlaceholder frameNumber =
    "Frame "
        ++ toString frameNumber
        ++ " Markdown\n\n"
        ++ "Highlight a chunk of code and explain it...\n\n\n"
        ++ markdownExplanatoryText


{-| A quick blurb about how to use markdown.
-}
markdownExplanatoryText : String
markdownExplanatoryText =
    "Markdown Example Usage\n\n"
        ++ "# Biggest Title\n"
        ++ "###### Smallest Title\n\n"
        ++ "[link name](https://google.com)\n\n"
        ++ "*italic text*\n"
        ++ "**bold text**\n\n"
        ++ "```LANGUAGE_NAME\n"
        ++ "...\n"
        ++ "code\n"
        ++ "...\n"
        ++ "```\n\n"
        ++ "> indented text"


{-| Used on the `Create` page.
-}
snipbitInfo : String
snipbitInfo =
    """SnipBits are uni-language snippets of code that are targetted at explaining simple individual concepts or
    answering questions.

    You highlight chunks of the code with attached comments, taking your viewers through your code explaining
    everything one step at a time.
    """


{-| Used on the `Create` page.
-}
bigbitInfo : String
bigbitInfo =
    """BigBits are multi-language projects of code targetted at simplifying larger tutorials which require their
    own file structure.

    You highlight chunks of code and attach comments automatically taking your user through all the files and
    folders in a directed fashion while still letting them explore themselves.
    """
