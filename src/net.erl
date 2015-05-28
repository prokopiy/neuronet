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
-export([loop/1, new/2, generate_layer/1, test/0, print/1, stop/1, pulse/2]).


new(Layers, Memory_length) ->

  Receptors_size = lists:nth(1, Layers),
  L1 = generate_layer(lists:duplicate(Receptors_size, 0)),

  M = lists:flatten(lists:map(fun(P) -> L = generate_layer(lists:seq(0, Memory_length)), neuron:register_link(P, L, 1),
    L end, L1)),

  Hidden_layers = lists:sublist(Layers, 2, length(Layers) - 2),
  L2 = generate_hidden_layers(Hidden_layers),

  Effectors_size = lists:last(Layers),
  L3 = generate_layer(lists:duplicate(Effectors_size, 0)),


%%   lists:foreach(fun(P) -> neuron:register_link(P, L3, 1) end, L1),


  link:register_layer_to_layer(M, lists:nth(1, L2)),
  link:register_between_layers(L2),
  link:register_layer_to_layer(lists:last(L2), L3),

  Data = #{
    hidden_layers => L2,
    receptors => L1,
    effectors => L3,
    memory => M
  },
  spawn(net, loop, [Data]).


test() ->
  Net1 = new([3, 2, 2, 1], 1),
  print(Net1),
  pulse(Net1, [1, 1, 1]),
  true.


print(Net) when is_pid(Net) ->
  Net ! {request, self(), print}.

stop(Net) when is_pid(Net) ->
  Net ! {request, self(), stop}.

pulse(Net, Powers) when is_pid(Net), is_list(Powers) ->
  Net ! {request, self(), {pulse, Powers}}.




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


pulse_to_layer([], []) ->
  true;
pulse_to_layer([NH | NT], [PH | PT]) when is_pid(NH) ->
  neuron:pulse(NH, PH),
  pulse_to_layer(NT, PT).



get_effect(Effectors, Data) when is_list(Effectors), is_map(Data) ->
%%   io:format("EFFFFFFFFFFFFFFFFFF,~w~n", [Effectors]),
  case {length(Effectors), maps:size(Data)} of
    {_X, _X} ->
      R = lists:map(fun(P) -> maps:get(P, Data) end, Effectors),
      R;
    {_X, _Y} ->
      io:format("~w X,Y=,~w, ~w~n", [self(), _X, _Y]),
      receive
        {reply, Pid, {effect, Value}} ->
          NewData = maps:put(Pid, Value, Data),
          get_effect(Effectors, NewData)
      after
        20000 ->
          {error, timeout}
      end
  end.


loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {request, Pid, print} ->
      io:format("Net~w ~w~n", [self(), Data]),
      io:format("Receptor layer:~n"),
      neuron:print(maps:get(receptors, Data)),
      io:format("Memory layer:~n"),
      neuron:print(maps:get(memory, Data)),
      io:format("Hidden layer:~n"),
      lists:foreach(fun(P) -> neuron:print(P) end, maps:get(hidden_layers, Data)),
      io:format("Effector layer:~n"),
      neuron:print(maps:get(effectors, Data)),
%%       Pid ! {reply, self(), ok},
      loop(Data);
    {request, Pid, {pulse, PowerList}} ->
      Receptors = maps:get(receptors, Data),
      pulse_to_layer(Receptors, PowerList),
      Effect = get_effect(maps:get(effectors, Data), #{}),
      Pid ! {repy, self(), {effect, Effect}},
      io:format("Net~w: send effect ~w to ~w~n", [self(), Effect, Pid]),
      loop(Data)

  after
    25000 ->
      true
  end.

