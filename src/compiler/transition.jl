function generate_transition(domain::Domain, state::State,
                             domain_type::Symbol, state_type::Symbol)
    transition_def = quote
        function transition(domain::$domain_type, state::$state_type,
                            term::Term; check::Bool=false)
            if term.name == PDDL.no_op.name && isempty(term.args)
                execute(domain, state, PDDL.NoOp(), term.args; check=check)
            else
                execute(domain, state, get_action(domain, term.name), term.args;
                        check=check)
            end
        end
        function transition!(domain::$domain_type, state::$state_type,
                             term::Term; check::Bool=false)
            if term.name == PDDL.no_op.name && isempty(term.args)
                execute(domain, state, PDDL.NoOp(), term.args; check=check)
            else
                execute(domain, state, get_action(domain, term.name), term.args;
                        check=check)
            end
        end
    end
    return transition_def
end
