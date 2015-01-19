%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Дек. 2014 0:01
%%%-------------------------------------------------------------------
-module(link).
-author("prokopiy").

%% API
-export([register_many_to_many/3, register_rnd/2]).


register_one_to_one(PidN1, PidN2, W) ->
  PidN1 ! {set_link_out, PidN2, W},
  PidN2 ! {set_link_in,  PidN1, W}.


register_one_to_many(_, [], _) ->
  true;
register_one_to_many(PidN, [H|T], [WH|WT]) ->
  register_one_to_one(PidN, H, WH),
  register_one_to_many(PidN, T, WT).


register_many_to_many([], _, _) ->
  true;
register_many_to_many([H1|T1], L, [WH|WT]) ->
  register_one_to_many(H1, L, WH),
  register_many_to_many(T1, L, WT).


register_rnd(L1, L2) ->
  W = lists:map(fun(X) -> lists:map(fun(Y) -> random:uniform() end, L2) end, L1),
  register_many_to_many(L1, L2, W).

