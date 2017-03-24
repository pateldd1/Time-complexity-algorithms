class Board
  attr_accessor :positions_to_open, :mapper, :length, :length2
  def initialize(dimensions)
    @mapper = Array.new(dimensions[0]+2){Array.new(dimensions[1])}
    @positions_to_open = (1..dimensions[0]).to_a.product((0...dimensions[1]).to_a).shuffle
    @length = @mapper.length - 1
    @length2 = @mapper[0].length - 1
  end
 
  def number_map
    @mapper.each_with_index do |bar,row|
      bar.map!.with_index do |val,col|
        if [row,col] == [0,0] 
          Tree.new([row,col],1)
        elsif [row,col] == [@length,@length2]
          Tree.new([row,col],1)
        elsif row == @mapper.length - 2
          Tree.new([@length,@length2],0)
        elsif row == 1
          Tree.new([0,0],0)
        elsif row == 0 && col > 0
          nil
        elsif row == @length && col < @length2
          nil
        else
          Tree.new([row,col],0)
        end
      end
    end
  end
  
  def [](pos)
    row,col = pos
    @mapper[row][col]
  end
  
  def []=(pos,id)
    row,col = pos
    @mapper[row][col] = id
  end
  
  def random_open
    pos = @positions_to_open.pop
    self[pos].open_position = true
    return pos
  end

  def east(pos)
    row,col = pos
    [row,col+1]
  end
  
  def west(pos)
    row,col = pos
    [row,col-1]
  end
  
  def north(pos)
    row,col = pos
    [row-1,col]
  end
  
  def south(pos)
    row,col = pos
    [row+1,col]
  end
  
  def offboard?(pos)
    row,col = pos
    row > @mapper.size - 2 || row < 1 || col > @mapper[0].size - 1 || col < 0
  end
  
  def neighbors(pos)
    [south(pos),west(pos),north(pos),east(pos)].select {|n| !offboard?(n) && self[n].open_position}
  end

  def complete
    self[self[[0,0]].parent].parent == self[self[[@length,@length2]].parent].parent
  end
  
  def make_connections(pos)
    # p "OPEN POSITIONS---------------------------------"
    # p @mapper[1..-2].map {|tree| tree.map{|tr| tr.open_position ? "X" : " "}}
     
    current_tree = self[pos]
    
    current_tree_parent = self[current_tree.parent]
    neighbor_trees = self.neighbors(pos).map do |position|
      self[position]
    end
    # .select {|tree| current_tree_parent.parent != self[tree.parent].parent}
   
    neighbor_tree_parents = neighbor_trees.map {|tree| self[tree.parent]}
    
    neighbor_tree_parents.each do |neighbor_tree_parent|
      if neighbor_tree_parent.rank == current_tree_parent.rank
        self.union(current_tree_parent,neighbor_tree_parent)
        if current_tree_parent.rank == 0
          neighbor_tree_parent.rank = 1
          current_tree_parent.rank = 0
        else
          neighbor_tree_parent.rank += current_tree_parent.rank
          current_tree_parent.rank = 0
        end
      elsif neighbor_tree_parent.rank > current_tree_parent.rank
        self.union(current_tree_parent,neighbor_tree_parent)
        current_tree_parent.rank = 0
      elsif neighbor_tree_parent.rank < current_tree_parent.rank
        self.union(neighbor_tree_parent,current_tree_parent)
        neighbor_tree_parent.rank = 0
      end
    end
  end

  def percolate
    # starting = Time.now
    counter = 0
    self.number_map
    until self.complete
      open_pos = self.random_open
      if !neighbors(open_pos).empty?
        self.make_connections(open_pos)
      end
      counter += 1
    end
    return counter
    # ending = Time.now
    # puts "#{(ending-starting)*1000} ms"
  end
  
   def union(lower_node,upper_node)
    children = []
    if lower_node.parent == upper_node.parent
      return
    end
    loop do
      next_node = self[lower_node.parent]
      if lower_node.parent == next_node.parent
        children << next_node
        break
      else
        children << next_node
        lower_node.parent = next_node.parent
      end
    end
    loop do
      next_node = self[upper_node.parent]
      if upper_node.parent == next_node.parent
        children.each {|child| child.parent = upper_node.parent}
        return
      else
        children << next_node
        upper_node.parent = next_node.parent
      end
    end
  end
end

class Tree
  attr_accessor :rank, :parent, :open_position
  
  def initialize(parent, rank, open_position = false)
    @parent = parent
    @rank = rank
    @open_position = open_position
  end
  
end
    
puts "Please input the dimensions of the graph(a,b):"
dimensions = gets.chomp
dimensions = dimensions.scan(/\d+/).map(&:to_i)
board = Board.new(dimensions)
board_area = dimensions[0]*dimensions[1]
sum = 0
100.times do
  board = Board.new(dimensions)
  sum += (board.percolate/board_area.to_f)
end
puts "Percolation Percentage is #{sum/100.to_f}"
  