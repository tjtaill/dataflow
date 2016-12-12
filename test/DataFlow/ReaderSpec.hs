module DataFlow.ReaderSpec where

import Data.Map as M

import Test.Hspec

import DataFlow.Assertions
import DataFlow.Core

spec :: Spec
spec =
  describe "readDiagram" $ do

    it "reads empty diagram" $
      "diagram {}" `shouldReadAsDiagram` Diagram M.empty [] []

    it "reads diagram with single attribute" $
      "diagram { name = \"\" }" `shouldReadAsDiagram` Diagram (M.singleton "name" (String "")) [] []

    it "reads diagram with multiple attributes" $
      let input = unlines [
                            "diagram {",
                            "  name = \"foo\"",
                            "  importance = \"high\"",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [("name", String "foo"),
                                                          ("importance", String "high")]) [] []


    it "reads diagram with whitespace inside braces" $
      "diagram {\n   \n    }" `shouldReadAsDiagram` Diagram M.empty [] []

    it "reads diagram with trust boundary" $
      let input = unlines [
                            "diagram {",
                            "  boundary foo {}",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          TrustBoundary "foo" M.empty []
        ] []
    it "reads diagram with trust boundary and nested nodes" $
      let input = unlines [
                            "diagram {",
                            "  boundary foo {",
                            "    io dynamo",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          TrustBoundary "foo" M.empty [
            InputOutput "dynamo" M.empty
          ]
        ] []
    it "reads diagram with function" $
      let input = unlines [
                            "diagram {",
                            "  function server",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          Node $ Function "server" M.empty
        ] []
    it "reads diagram with database" $
      let input = unlines [
                            "diagram {",
                            "  database dynamo",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          Node $ Database "dynamo" M.empty
        ] []
    it "reads diagram with io" $
      let input = unlines [
                            "diagram {",
                            "  io analytics",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          Node $ InputOutput "analytics" M.empty
        ] []
    it "reads diagram with flow" $
      let input = unlines [
                            "diagram {",
                            "  a -> b",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [] [
          Flow "a" "b" M.empty
        ]
    it "does not allow multiline string" $
      let input = unlines [
                            "diagram {",
                            "  foo = \"",
                            "  omg",
                            "  yes",
                            "  \"",
                            "}"
                          ]
      in shouldFailReadAsDiagram input
    it "reads attributes" $
      let input = unlines [
                            "diagram {",
                            "  io baz {",
                            "    title = \"foo\"",
                            "    description = \"bar\"",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          Node $ InputOutput "baz" (M.fromList [("title", String "foo"),
                                                ("description", String "bar")])
        ] []
    it "reads multiple attributes on a single line" $
      let input = unlines [
                            "diagram {",
                            "  io baz {",
                            "    title = \"foo\" description = \"bar\"",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          Node $ InputOutput "baz" (M.fromList [("title", String "foo"),
                                                ("description", String "bar")])
        ] []
    it "reads attributes and nodes" $
      let input = unlines [
                            "diagram {",
                            "  name = \"bar\"",
                            "  io baz {",
                            "    title = \"foo\"",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.singleton "name" (String "bar")) [
          Node $ InputOutput "baz" (M.singleton "title" (String "foo"))
        ] []
    it "reads flow with attributes" $
      let input = unlines [
                            "diagram {",
                            "  foo -> bar {",
                            "    title = \"baz\"",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [] [
          Flow "foo" "bar" (M.singleton "title" (String "baz"))
        ]
    it "reads text blocks" $
      let input = unlines [
                            "diagram {",
                            "  foo -> bar {",
                            "    description = `Hello,",
                            "                   \"evil\"",
                            "                   world!`",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [] [
          Flow "foo" "bar" (M.singleton "description" (String "Hello,\n\"evil\"\nworld!"))
        ]
    it "only allows boundaries in top-level diagram" $
      let input = unlines [
                            "diagram {",
                            "  boundary {",
                            "     boundary {}",
                            "  }",
                            "}"
                          ]
      in shouldFailReadAsDiagram input
    it "does not allow flow inside boundary" $
      let input = unlines [
                            "diagram {",
                            "  boundary {",
                            "     a -> b",
                            "  }",
                            "}"
                          ]
      in shouldFailReadAsDiagram input
    it "does not allow flow before node" $
      let input = unlines [
                            "diagram {",
                            "  a -> b",
                            "  io a",
                            "}"
                          ]
      in shouldFailReadAsDiagram input
    it "can read first flow with id starting with b (conflicting with boundary)" $
      let input = unlines [
                            "diagram {",
                            "  boundary foo {}",
                            "  bar -> baz {",
                            "  }",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [
          TrustBoundary "foo" M.empty []
        ] [
          Flow "bar" "baz" M.empty
        ]
    it "ignores comments" $
      let input = unlines [
                            "diagram {",
                            "  /* Yes, comments!",
                            "   * Yes, more comments!",
                            "   * Yes, even more comments! */",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [] []
    it "ignores comments outside diagram" $
      let input = unlines [
                            "/* Header */",
                            "diagram {",
                            "}",
                            "/* Footer */"
                          ]
      in input `shouldReadAsDiagram` Diagram M.empty [] []
    it "reads empty array" $
      let input = unlines [
                            "diagram {",
                            "  things = []",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [])
      ]) [] []
    it "reads array with one string" $
      let input = unlines [
                            "diagram {",
                            "  things = [\"hello\"]",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [String "hello"])
      ]) [] []
    it "reads array of strings" $
      let input = unlines [
                            "diagram {",
                            "  things = [\"foo\", \"bar\"]",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [String "foo", String "bar"])
      ]) [] []
    it "reads array of arrays of strings" $
      let input = unlines [
                            "diagram {",
                            "  things = [",
                            "    [\"foo\", \"bar\"]",
                            "  ]",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [Array [String "foo", String "bar"]])
      ]) [] []
    it "reads array with one text block" $
      let input = unlines [
                            "diagram {",
                            "  things = [",
                            "    `Hello`",
                            "  ]",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [String "Hello"])
      ]) [] []
    it "reads array with text blocks" $
      let input = unlines [
                            "diagram {",
                            "  things = [",
                            "    `Hello`,",
                            "    `,",
                            "     world`",
                            "  ]",
                            "}"
                          ]
      in input `shouldReadAsDiagram` Diagram (M.fromList [
        ("things", Array [String "Hello", String ",\nworld"])
      ]) [] []
