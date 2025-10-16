-- |
-- Module      :  Magix.Languages.Common.Expression
-- Description :  Common definitions related to handling Nix expressions
-- Copyright   :  2025 Dominik Schrempf
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-- Creation date: Fri Apr 11 06:36:34 2025.
module Magix.Languages.Common.Expression
  ( Replacement,
    getCommonReplacements,
    packageToExpression
  )
where

import Data.Text (Text, pack, breakOn)
import qualified Data.Text as Text
import Magix.Config (Config (..))

type FlakeRef = (Text, Text)
type Replacement = (Text, Text)

isFlakeReference :: Text -> Maybe FlakeRef
isFlakeReference pn | Text.any (\c -> '#' == c || ':' == c || '/' == c || '\\' == c) pn = -- package names don't contain these symbols but flake references do
                      let (flakePath, packageRef) = breakOn "#" pn
                      in pure $ (flakePath, if Text.null packageRef then pack "default" else Text.dropWhile ('#' ==) packageRef)
                    | otherwise = -- not a flake reference
                      Nothing

flakeExpr :: FlakeRef -> Text
flakeExpr (p, pn) = pack "(builtins.getFlake \"" <> p <> pack "\").packages.${builtins.currentSystem}." <> pn

packageToExpression :: Text -> Text
packageToExpression pn = maybe pn flakeExpr $ isFlakeReference pn

getCommonReplacements :: Config -> [Replacement]
getCommonReplacements c =
  [ ("__SCRIPT_NAME__", pack $ scriptName c),
    ("__SCRIPT_SOURCE__", pack $ scriptLinkPath c)
  ]
