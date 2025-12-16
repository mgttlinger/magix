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
  ( FlakeRef,
    Replacement,
    getCommonReplacements,
    flakeInput,
    flakeRef,
    flakeOverride,
    partitionFlakes,
    noOverride,
    overrides,
    packageToExpression
  )
where

import Data.Char (isAlphaNum)
import Data.Maybe (fromMaybe)
import Data.Text (Text, breakOn, pack, takeWhileEnd)
import qualified Data.Text as Text
import Magix.Config (Config (..))

type FlakeRef = (Text, Maybe Text)
type Replacement = (Text, Text)
type Override = (Text, FlakeRef)

isFlakeReference :: Text -> Maybe FlakeRef
isFlakeReference pn | Text.any (\c -> '#' == c || ':' == c || '/' == c || '\\' == c) pn = -- package names don't contain these symbols but flake references do
                      let (flakePath, packageRef) = breakOn "#" pn
                      in pure $ (flakePath, if Text.null packageRef then Nothing else pure $ Text.dropWhile ('#' ==) packageRef)
                    | otherwise = -- not a flake reference
                      Nothing

partitionFlakes :: [Text] -> ([Text], [FlakeRef])
partitionFlakes [] = ([], [])
partitionFlakes (pn : pns) = let (ops, ofrs) = partitionFlakes pns in
  case isFlakeReference pn of
    Just fr -> (ops, fr : ofrs)
    Nothing -> (pn : ops, ofrs)

flakeName :: FlakeRef -> Text
flakeName (p, _) = takeWhileEnd isAlphaNum p

flakeInput :: FlakeRef -> Text
flakeInput r@(p, _) = flakeName r <> pack " = { url = \"" <> p <> pack "\"; inputs.nixpkgs.follows = \"nixpkgs\"; };"

flakeRef :: FlakeRef -> Text
flakeRef r@(_, pn) = pack "inputs." <> flakeName r <> pack ".packages.${system}." <> fromMaybe "default" pn

flakeExpr :: FlakeRef -> Text
flakeExpr (p, pn) = pack "(builtins.getFlake \"" <> p <> pack "\").packages.${builtins.currentSystem}." <> fromMaybe "default" pn

flakeOverride :: FlakeRef -> Override
flakeOverride r@(_, Just pn) = (pn, r)
flakeOverride r@(_, Nothing) = (flakeName r, r)

overrideExpression :: Override -> Text
overrideExpression (p, fr) = p <> pack " = " <> flakeRef fr <> pack ";"

overrides :: [Override] -> Text
overrides = Text.unlines . map overrideExpression

noOverride :: Either Text Override -> Text
noOverride (Left t) = t
noOverride (Right (_, fr)) = flakeExpr fr

packageToExpression :: Text -> Either Text Override
packageToExpression pn = maybe (Left pn) (Right . flakeOverride) $ isFlakeReference pn

getCommonReplacements :: Config -> [Replacement]
getCommonReplacements c =
  [ ("__SCRIPT_NAME__", pack $ scriptName c),
    ("__SCRIPT_SOURCE__", pack $ scriptLinkPath c)
  ]
