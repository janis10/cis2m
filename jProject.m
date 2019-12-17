function [A,b] = jProject(Asp,bsp,n,verbose)

%% Authors: Tzanis Anevlavis, Paulo Tabuada
% Copyright (C) 2019, Tzanis Anevlavis, Paulo Tabuada
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
% This code is part of the implementation of the algorithm proposed in:
% Tzanis Anevlavis and Paulo Tabuada, "Computing controlled invariant sets
% in two moves", in 2019 IEEE Conference on Decision and Control, 
% and is publicly available at: https://github.com/janis10/cis2m
%
% For any comments contact Tzanis Anevlavis @ janis10@ucla.edu.
%
%
%
%
%% Description:
% This function takes as input a set {x| Ax <= b} in a higher dimensional
% space in terms of the matrices A, b, and the dimension n back to which we
% want to project the aforementioned set.
%
% It returns matrices Asp, bsp that constitute the set in \R^n.
%
% Inputs:   Asp, bsp such that {x| Asp x <= bsp} in \R^m, m > n.
%           n = dimension into which the above set is projected.
%           verbose = 0 - no messages; 1 - displays messages.
%
% Outputs: A, b such that {x| A x <= b} is the projected set in \R^n.
%
% This function is a variant of the algorithm proposed by:
% A. Simon and A. King, ``Exploiting sparsity in polyhedral analysis,''
% in Proceedings of the 12th International Conference on Static Analysis,
% ser. SAS'05. Berlin, Heidelberg: Springer- Verlag, 2005, pp. 336-351.
%
% Here however, we utilize exact projection instead of approximating it,
% and allow the system to grow a little beyond the original size (ln:89).
%
% This function makes use of the Multi-Parametric Toolbox 3.0:
% M. Herceg, M. Kvasnica, C. Jones, and M. Morari,
% ``Multi-Parametric Toolbox 3.0,'' in Proc. of the European Control
% Conference, Z�rich, Switzerland, July 17-19 2013, pp. 502-510,
% http://control.ee.ethz.ch/ mpt.

%% Project back to original space using iterative FME exploiting sparsity.

% First remove redundant inequalities. This is important to have faster
% projection.
A = full(Asp);
b = full(bsp);

if (verbose)
    disp('Obtaining minimum representation..')
end
mcisHmat = [A b];
P = Polyhedron('H',mcisHmat);
P = P.minHRep();
mcisHmat = P.H;
A = mcisHmat(:,1:end-1);
b = mcisHmat(:,end);
if (verbose)
    disp('..done!')
end

if (verbose)
	disp('Begin projection back to original space..')
end

% Number of constraints.
N = size(A,1);
% Number of variables to be eliminated.
V = size(A,2);
m = V-n;
% Set limit for growth.
limit = size(A,1) + ceil(0.125*N);

% Find the variable to be eliminated, and place it last.
[f_elim,growth] =  jSelect(A,n);
A = A(:,[1:f_elim-1 f_elim+1:end f_elim]);

cnt = m;

% Classic Fourier-Motzkin Elimination (FME) with smart selection of vars to
% eliminate, and intermediate removal of redundant inequalities until the 
% resulting system of inequalities grows beyond some limit. Then use MPT3 
% built-in tool for remaining variables.
while (cnt>0 && N+growth<limit)
    % FME:
    tmp = fourier([A b],1:V-1);
    A = tmp(:,1:end-1);
    b = tmp(:,end);
    % Update cnt and size of A.
    cnt = cnt - 1;
    V = V - 1;
    N = size(A,1);
    if (cnt>0)
        % Find the variable to be eliminated, and place it last.
        [f_elim,growth] =  jSelect(A,n);
        A = A(:,[1:f_elim-1 f_elim+1:end f_elim]);

        if (N+growth>limit)
            % Remove vacuously satisfied inequalities.
            % by implementing a simple LP.
            [A,b] = jCompress(A,b);
            % Update N and limit.
            N = size(A,1);
            limit = size(A,1) + ceil(0.125*N);
            % Find the variable to be eliminated, and place it last.
            [f_elim,growth] =  jSelect(A,n);
            A = A(:,[1:f_elim-1 f_elim+1:end f_elim]);
        end
    end
end
% If there are variables remaining, use MPT3 projection function.
% Check for remaining variables.
if (cnt>0)
    % Use projection from MPT:
    if (verbose)
    	disp('Limit exceeded; will use MPT3 projection..')
    end
    tmpP = Polyhedron('H',[A b]);
    tmpP = tmpP.projection((1:n),'ifourier');
    A = tmpP.A;
    b = tmpP.b;
end

if (verbose)
	disp('..done!')
end