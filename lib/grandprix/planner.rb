class Grandprix::Planner
  def initialize(graph)
    @graph = graph
  end

  def plan(topology, elements_array)
    elements = Grandprix::Elements.build elements_array

    nested_dependencies = project_array(topology, "after")
    alongside = project_array(topology, "alongside")

    dependencies = flatten_edges nested_dependencies

    full_dependencies = dependencies.flat_map do |from, to|
      extended_from = alongside[from] + [from]
      extended_to   = alongside[  to] + [to  ]
      new_deps = extended_from.product extended_to

      eliminate_self_loops compact_pairs(new_deps)
    end

    before_relation = invert full_dependencies

    in_order = @graph.sort before_relation

    full_elements = elements.alongside alongside
    independent_elements = elements.except in_order
    elements_in_order = full_elements.reorder in_order 

    all = independent_elements + elements_in_order
    all.annotate project(topology, "annotation")
  end

  private
  def project_array(hash, key)
    projected = project(hash, key)
    projected.tap { |h| h.default = [] }
  end

  def project(hash, key)
    Hash[ compact_pairs hash.map{|element, config| [element, config[key]]} ]
  end

  def invert(edges)
    edges.map {|k, v| [v, k]}
  end

  def compact_pairs(pairs)
    pairs.reject do |pair|
      pair.nil? || pair[0].nil? || pair[1].nil?
    end
  end

  def eliminate_self_loops(pairs)
    pairs.reject {|x, y| x == y }
  end

  def flatten_edges(vertex_to_successors)
    vertex_to_successors.flat_map {|vertex_j, successors| successors.map {|vertex_k| [vertex_j, vertex_k] } }
  end

end
