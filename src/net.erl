%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Дек. 2014 21:52
%%%-------------------------------------------------------------------
-module(net).
-author("prokopiy").

%% API
-export([loop/1, new/2, generate_layer/1, test/0, print/1, stop/1]).


new(Layers, Memory_length) ->

  Receptors_size = lists:nth(1, Layers),
  L1 = generate_layer(lists:duplicate(Receptors_size, 0)),

  Effectors_size = lists:last(Layers),
  L3 = generate_layer(lists:duplicate(Effectors_size, 0)),

  Hidden_layers = lists:sublist(Layers, 2, length(Layers) - 2),
  L2 = generate_hidden_layers(Hidden_layers),

  lists:foreach(fun(P) -> neuron:register_link(P, L3, 1) end, L1),

  Data = #{
    hidden_layers => L2,
    receptors => L1,
    effectors => L3,
    memory => []
  },
  spawn(net, loop, [Data]).


test() ->
  Net1 = new([3, 2, 3, 1], 5),
  print(Net1),
  true.


print(Net) when is_pid(Net) ->
  Net ! {request, self(), print}.

stop(Net) when is_pid(Net) ->
  Net ! {request, self(), stop}.



generate_layer(A) ->
  generate_layer(A, []).
generate_layer([], Acc) ->
  Acc;
generate_layer([H | T], Acc) ->
  N = neuron:new(H),
  generate_layer(T, Acc ++ [N]).



generate_hidden_layers(L) ->
  generate_hidden_layers(L, []).
generate_hidden_layers([], Acc) ->
  Acc;
generate_hidden_layers([H | T], Acc) ->
  L = generate_layer(lists:duplicate(H, 0)),
  generate_hidden_layers(T, Acc ++ [L]).



loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {request, Pid, print} ->
      io:format("Net~w ~w~n", [self(), Data]),
      neuron:print(maps:get(receptors, Data)),
      neuron:print(maps:get(effectors, Data)),
%%       Pid ! {reply, self(), ok},
      loop(Data);
    {request, Pid, {pulse, From, PowerList}} ->
       {receptors, FL} = lists:keyfind(receptors, 1, Data),
       lists:foreach(fun(P) -> P ! {self(), stop} end, FL)

  after
    25000 ->
      true
  end.

