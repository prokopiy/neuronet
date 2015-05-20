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
-export([register_neuron_to_neuron/2, register_neuron_to_neuron/3, register_neuron_to_layer/2, register_neuron_to_layer/3, register_layer_to_layer/2, register_layer_to_layer/3, register_between_layers/1]).
%%

register_neuron_to_neuron(Pid_neuron_from, Pid_neuron_to) ->
  neuron:register_link(Pid_neuron_from, Pid_neuron_to, random:uniform()).

register_neuron_to_neuron(Pid_neuron_from, Pid_neuron_to, W) ->
  neuron:register_link(Pid_neuron_from, Pid_neuron_to, W).


register_neuron_to_layer(PidN, Layer) ->
  lists:foreach(fun(P) -> register_neuron_to_neuron(PidN, P) end, Layer).

register_neuron_to_layer(_, [], _) ->
  true;
register_neuron_to_layer(PidN, [H | T], [WH | WT]) ->
  register_neuron_to_neuron(PidN, H, WH),
  register_neuron_to_layer(PidN, T, WT).


register_layer_to_layer(L1, L2) ->
  lists:foreach(fun(P) -> register_neuron_to_layer(P, L2) end, L1).

register_layer_to_layer([], _, _) ->
  true;
register_layer_to_layer([H], L, W) ->
  register_neuron_to_layer(H, L, W);
register_layer_to_layer([H1 | T1], L, [WH | WT]) ->
  register_neuron_to_layer(H1, L, WH),
  register_layer_to_layer(T1, L, WT).


register_between_layers([L1, L2]) ->
  register_layer_to_layer(L1, L2).


