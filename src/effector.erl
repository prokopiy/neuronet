%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Дек. 2014 13:32
%%%-------------------------------------------------------------------
-module(effector).
-author("prokopiy").

%% API
-export([new/0, loop/1]).

%%

new() ->
  E = [],
  spawn(effector, loop, [E]).



loop(N) ->
  receive
    {pulse, PidN, Power} ->
      io:format("Effector~w: ~w~n", [self(), Power]),
      loop(N)

  after
    27000 ->
      io:format("Effector~w timeout~n", [self()])
  end.