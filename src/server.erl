%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Дек. 2014 12:26
%%%-------------------------------------------------------------------
-module(server).
-author("prokopiy").

%% API
-export([start/0, loop/1]).

%%
start() ->
  io:format("Neuronet server started at ~w on ~w~n", [self(), node()]),
  {A1, A2, A3} = now(),
  random:seed(A1, A2, A3),

  Data = #{
    owner => self(),
    clients_pid => []

  },
  register(mbox, spawn(server, loop, [Data])),
  receive
    A ->
      io:format("~w~n", [A])
  end.

%%   spawn(server, loop, [Data]).
%%   loop(Data).


loop(Data) ->
  receive
    A ->
      io:format("main:loop(): ~w ~n", [A]),
      loop(Data)
  after
    25000 ->
      io:format("Neuronet server stopped~n"),
      maps:get(owner, Data) ! true
  end.



reply(Pid, Reply) ->
  Pid ! {reply, Reply}.