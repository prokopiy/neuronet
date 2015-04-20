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
-export([loop/1, gen_neurons/1, new/0]).

%%

gen_neurons(0) ->
  [];
gen_neurons(N) ->
  [neuron:new()] ++ gen_neurons(N - 1).

new() ->
  N = [{neurons, []}, {receptors, []}, {effectors, []}],
  spawn(net, loop, [N]).



loop(N) ->
  receive
    {reply, _, ok} ->
      loop(N)
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
