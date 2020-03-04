function [A,b] = jCompress(A,b)
%% Authors: Tzanis Anevlavis.
% Copyright (C) 2019, Tzanis Anevlavis.
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <http://www.gnu.org/licenses/>.
%
%
% This code is part of the Controlled Invariance in 2 Moves repository
% (CIS2M), and is publicly available at: https://github.com/janis10/cis2m .
%
% For any comments contact Tzanis Anevlavis @ janis10@ucla.edu.
%
%
%
%
%% Description:
% This function checks if an inequality is always satisfied given the
% remaining inequalities. If it does, it is reduntant and we remove it.
%
% Input:    Matrices A \in \R^{q,n}, b \in \R^{q}
%
% Output:   Matrices A \in \R^{q',n}, b \in \R^{q'}, q' <= q.
%
% On the TOLERANCE used:
%   As a comparison MPT3 uses by default:
%             rel_tol: 1e-06
%             abs_tol: 1e-08
%             lex_tol: 1e-10
%             zero_tol: 1e-12
%   and we use:
% jAbs = 1e-10;

% Use a simple linear program for the rest of the inequalities.
q = size(A,1);
idx = zeros(q,1);   % Indices to be removed
parfor i = 1:q
    % Add as an extra constraint an upper bounf of b(i)+0.1 to avoid
    % returning INF
    tmpA = [A; A(i,:)];
    tmpb = [b; b(i)+0.1];
    % Remove the i-th inequality from the system (inequality-to-be-checked)
    tmpA(i,:) = [];
    tmpb(i) = [];
    % .. and use it as an objective, with "-" sign, since we maximize
    tmpObj = full(-A(i,:));
    
    meth = 0;
    if (meth==1)
        % Uses MOSEK:
        [~,fval] = linprog(tmpObj,tmpA,tmpb);
        val = -fval;
    else
        % Uses Gurobi:
        [~,fval,exitflag] = linprogGurobi(tmpObj,tmpA,tmpb);
        if (exitflag == 0)
            warning('0  maximum number of iterations reached (ITERATION_LIMIT');
        elseif (exitflag == -2)
            error('-2  no feasible point found (INFEASIBLE, NUMERIC, ...');
        elseif (exitflag == -3)
            error('-3  problem is unbounded (UNBOUNDED)');
        end
        val = -fval;
    end
    if (val <= b(i))
%     if (val-b(i) <= jAbs)
        idx(i) = i;
    end
end

idx = (idx~=0);
A(idx,:) = [];
b(idx,:) = [];