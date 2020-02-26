"Convert type hierarchy to list of Julog clauses."
function type_clauses(typetree::Dict{Symbol,Vector{Symbol}})
    clauses = [[Clause(@julog($ty(X)), Term[@julog($s(X))]) for s in subtys]
               for (ty, subtys) in typetree if length(subtys) > 0]
    return length(clauses) > 0 ? reduce(vcat, clauses) : Clause[]
end

"Convert list of clauses to a state description."
function clauses_to_state(clauses::Vector{Clause})
    facts = Clause[]
    fluents = Dict{Symbol,Any}()
    for c in clauses
        if c.head.name == :(==)
            # Initialize fluents
            term, val = c.head.args[1], c.head.args[2]
            @assert !isa(term, Var) "Initial terms cannot be unbound variables."
            @assert isa(val, Const) "Terms must be initialized to constants."
            if isa(term, Const)
                # Assign term to constant value
                fluents[term.name] = val.name
            else
                # Assign entry in look-up table
                lookup = get!(fluents, term.name, Dict())
                lookup[Tuple(a.name for a in term.args)] = val.name
            end
        else
            push!(facts, c)
        end
    end
    return State(facts, fluents)
end

"Check whether formulas can be satisfied in a given state."
function satisfy(formulas::Vector{<:Term}, state::State,
                 domain::Union{Domain,Nothing}=nothing; mode::Symbol=:any)
    # Initialize Julog knowledge base to the set of facts
    clauses = state.facts
    # If domain is provided, add domain axioms and type clauses
    if domain != nothing
        clauses = Clause[clauses; domain.axioms; type_clauses(domain.types)]
    end
    # Pass in fluents as a dictionary of functions
    funcs = state.fluents
    return resolve(formulas, clauses; funcs=funcs, mode=mode)
end

satisfy(formula::Term, state::State, domain::Union{Domain,Nothing}=nothing;
        options...) = satisfy(Term[formula], state, domain; options...)

"Evaluate formula within a given state."
function evaluate(formula::Term, state::State,
                  domain::Union{Domain,Nothing}=nothing; as_const::Bool=true)
    # Evaluate formula as fully as possible
    val = eval_term(formula, Julog.Subst(), state.fluents)
    # Return if formula evaluates to a Const (unwrapping if as_const=false)
    if isa(val, Const) return as_const ? val : val.name end
    # If val is not a Const, check if holds true in the state
    sat, _ = satisfy(Term[val], state, domain)
    return as_const ? Const(sat) : sat # Wrap in Const if as_const=true
end

"Create initial state from problem definition."
function initialize(problem::Problem)
    types = [@julog($ty(:o) <<= true) for (o, ty) in problem.objtypes]
    state = clauses_to_state(problem.init)
    append!(state.facts, types)
    return state
end

"Simulate a step forward (action + triggered events) in a domain."
function step(domain::Domain, state::State, action::Term)
    state = execute(act, state, domain)
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
    end
    return state
end

function step(domain::Domain, state::State, actions::Set{<:Term})
    state = execpar(actions, state, domain) # Execute in parallel
    if length(domain.events) > 0
        state = trigger(domain.events, state, domain)
    end
    return state
end

"Simulate state trajectory for a given domain and sequence of actions."
function simulate(domain::Domain, state::State, actions::Vector{<:Term})
    trajectory = State[state]
    for act in actions
        state = step(domain, state, act)
        push!(trajectory, state)
    end
    return trajectory
end

function simulate(domain::Domain, state::State, actions::Vector{Set{<:Term}})
    trajectory = State[state]
    for acts in actions
        state = step(domain, state, acts)
        push!(trajectory, state)
    end
    return trajectory
end

"Access the value of a fluent or fact in a state."
function Base.getindex(state::State, f::Union{String,Number,Symbol,Expr})
    f = isa(f, String) ? Parser.parse_formula(f) : eval(Julog.parse_term(f))
    return evaluate(f, state, nothing, as_const=false)
end

function Base.getindex(state::State, domain::Domain,
                       f::Union{String,Number,Symbol,Expr})
    f = isa(f, String) ? Parser.parse_formula(f) : eval(Julog.parse_term(f))
    return evaluate(f, state, domain, as_const=false)
end
