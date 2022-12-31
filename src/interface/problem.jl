"""
    Problem

Abstract supertype for planning problems, which specify the initial state of
a planning domain and the task specification to be achieved.
"""
abstract type Problem end

"""
$(SIGNATURES)

Returns the name of a problem.
"""
get_name(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the name of a problem's domain.
"""
get_domain_name(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns an iterator over objects in a `problem`.
"""
get_objects(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns a map from problem objects to their types.
"""
get_objtypes(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns a list of terms that determine the initial state.
"""
get_init_terms(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the goal specification of a problem.
"""
get_goal(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the metric specification of a problem.
"""
get_metric(problem::Problem) = error("Not implemented.")

"""
$(SIGNATURES)

Returns the constraint specification of a problem.
"""
get_constraints(problem::Problem) = error("Not implemented.")
