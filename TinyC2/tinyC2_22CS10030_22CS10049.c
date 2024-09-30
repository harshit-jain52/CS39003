#include "lex.yy.c"
#include "y.tab.c"

void throw_error(char *err){
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
}

// function to create node of the parse tree, with the production to output 
// and the number of children: using variadic functions
parse_tree_node* create_node(char* production_text, int num_children, ...) {
	parse_tree_node* new_node = (parse_tree_node*)malloc(sizeof(parse_tree_node));
	new_node->text = strdup(production_text);
	new_node->children = NULL;

	if(!num_children) return new_node;

	va_list args; // for handling variable number of children
	va_start(args, num_children); // initialize the va_list
	new_node->children = add_child_node(va_arg(args, parse_tree_node*));
	node_child_list* mover = new_node->children;
	int ct = 1;

	// va_arg updates the va_list to the next argument

	while(ct < num_children){
		mover->next = add_child_node(va_arg(args, parse_tree_node*));
		mover = mover->next;
		ct++;
	}
	va_end(args);
	return new_node;
}

// function to add a node to the linked list of children of a node
node_child_list* add_child_node(parse_tree_node* data){
	node_child_list* temp = (node_child_list*)malloc(sizeof(node_child_list));
	temp->child = data;
	temp->next = NULL;
	return temp;
}

// frees the node memory of the parse tree
void clean_parse_tree(parse_tree_node* root){
	if(root == NULL) return;
	node_child_list* mover = root->children;
	while(mover != NULL){
		node_child_list* temp = mover;
		mover = mover->next;
		clean_parse_tree(temp->child);
		free(temp);
	}
	free(root->text);
	free(root);
}

// prints the production in NLR format (LR representing left to right child printing)
void print_productions(parse_tree_node* root, int level){
	if(root == NULL) return;
	print_spaces(level);
	printf("%s\n", root->text);
	node_child_list* mover = root->children;
	while(mover != NULL){
		print_productions(mover->child, level+1);
		mover = mover->next;
	}
}

// spaces for tree printing
void print_spaces(int num){
    for(int i = 0; i < num; i++) printf("  ");
}

int main(){
    yyparse();
}