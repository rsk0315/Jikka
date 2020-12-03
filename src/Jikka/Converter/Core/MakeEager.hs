{-# LANGUAGE LambdaCase #-}

-- |
-- Module      : Jikka.Converter.Core.MakeEager
-- Description : convert exprs for eager evaluation.
-- Copyright   : (c) Kimiyuki Onaka, 2020
-- License     : Apache License 2.0
-- Maintainer  : kimiyuki95@gmail.com
-- Stability   : experimental
-- Portability : portable
--
-- `Jikka.Language.Core.MakeEager` wraps some exprs with lambda redundant things from AST.
-- Specifically, this converts @if p then a else b@ to @(if p then (lambda x. a) else (lambda x. b)) 0@.
module Jikka.Converter.Core.MakeEager
  ( run,
  )
where

import Jikka.Language.Core.Expr
import Jikka.Language.Core.Lint (typecheckProgram')

makeEagerExpr :: Expr -> Expr
makeEagerExpr = \case
  Var x -> Var x
  Lit lit -> Lit lit
  App f args -> case (makeEagerExpr f, args) of
    (Builtin (If t), [p, a, b]) -> App (AppBuiltin (If (FunTy [] t)) [makeEagerExpr p, Lam [] (makeEagerExpr a), Lam [] (makeEagerExpr b)]) []
    (f, _) -> App f (map makeEagerExpr args)
  Lam args e -> Lam args (makeEagerExpr e)
  Let x t e1 e2 -> Let x t (makeEagerExpr e1) (makeEagerExpr e2)

makeEagerToplevelExpr :: ToplevelExpr -> ToplevelExpr
makeEagerToplevelExpr e = case e of
  ResultExpr e -> ResultExpr $ makeEagerExpr e
  ToplevelLet rec x args ret body cont -> ToplevelLet rec x args ret (makeEagerExpr body) (makeEagerToplevelExpr cont)

run :: Program -> Either String Program
run = typecheckProgram' . makeEagerToplevelExpr
