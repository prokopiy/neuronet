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
-export([loop/1, new/2, generate_layer/1, test/0]).


new(Layers, Memory_length) ->

  Receptors_size = lists:nth(1, Layers),
  L1 = generate_layer(generate_list_of(0, Receptors_size, [])),

  Effectors_size = lists:last(Layers),
  L3 = generate_layer(generate_list_of(0, Effectors_size, [])),

  Hidden_layers = lists:sublist(Layers, 2, length(Layers) - 2),
  L2 = generate_hidden_layers(Hidden_layers),


  N = [{hidden_layers, L2}, {receptors, L1}, {effectors, L3}, {memory, []}],
  spawn(net, loop, [N]).


test() ->

  Net1 = new([3, 2, 2, 1], 5),
  Net1 ! {request, self(), print_message()},

  true.


print_message() ->
  print.


generate_list_of(V, Length) ->
  generate_list_of(V, Length, []).
generate_list_of(V, 0, Acc) ->
  Acc;
generate_list_of(V, Length, Acc) ->
  generate_list_of(V, Length - 1, [V] ++ Acc).

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
  L = generate_layer(generate_list_of(0, H)),
  generate_hidden_layers(T, Acc ++ [L]).



loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {request, Pid, print} ->
      io:format("Net~w ~w~n", [self(), Data]),
      Pid ! {reply, self(), ok},
      loop(Data)
  after
    25000 ->
      true
  end.


%% generate_perceptron_data([N1, N2]) ->
%%   L1 = gen_neurons(N1),
%%   L2 = gen_neurons(N2),
%%   link:register_rnd(L1, L2),
%%   {neurons, [L1, L2]};
%% generate_perceptron_data([H | T]) ->
%%   L1 = gen_neurons(H),
%%   R = generate_perceptron_data(T),
%%   {neurons, L2} = R,
%%   [HL2 | _] = L2,
%%   link:register_rnd(L1, HL2),
%%   {neurons, [L1 | L2]}.
%%
%%
%% generate_perceptron(N) ->
%%   D = [{type, perceptron}, {layers_sizes, N}, generate_perceptron_data(N)],
%%   io:format("D=~w~n", [D]),
%%   spawn(net, loop, [D]).
%%
%%
%% loop(N) ->
%%   receive
%%     {Pid, stop} ->
%%       {neurons, L} = lists:keyfind(neurons, 1, N),
%%       FL = lists:flatten(L),
%%       lists:foreach(fun(P) -> P ! {self(), stop} end, FL),
%%       io:format("Net~w stop~n", [self()]);
%%     {Pid, print} ->
%%       io:format("Net~w:~n", [self()]),
%%       {neurons, L} = lists:keyfind(neurons, 1, N),
%%       FL = lists:flatten(L),
%%       lists:foreach(fun(P) -> P ! {self(), print} end, FL),
%%       loop(N);
%%     {Pid, pulse, P} ->
%%       {neurons, [H | _]} = lists:keyfind(neurons, 1, N),
%% %%       io:format("Net~w: pulse to neurons...~n", [self()]),
%%       neuron:pulse_to_neurons_list(H, P),
%%       receive
%%         {effect, Value} ->
%% %%           io:format("Net receive pulse value: ~w~n", [Value]),
%%           Pid ! {reply, self(), {effect, Value}};
%%         Other ->
%%           io:format("Net~w receiving: ~w~n", [self(), Other])
%%
%%       end,
%%       loop(N)
%%
%%
%%   after
%%     25000 ->
%%       io:format("Net~w timeout~n", [self()])
%%   end.
