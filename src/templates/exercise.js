import * as React from "react"
import { graphql } from "gatsby"

import Burrito from "../components/burrito"
import Seo from "../components/seo"
import Tags from "../components/tags"

const ExerciseTemplate = ({ data, location }) => {
  const post = data.markdownRemark
  const siteTitle = data.site.siteMetadata?.title

  return (
    <Burrito location={location} title={siteTitle}>
      <Seo title={post.frontmatter.title} description={post.excerpt} />
      <div className="exercise">
        <header>
          <h2 itemProp="headline">{post.frontmatter.title}</h2>
        </header>
        <section>
          {post.frontmatter.tags && (
            <Tags
              tags={post.frontmatter.tags}
              tagSlugs={post.fields.tagSlugs}
            />
          )}
        </section>
        <section
          dangerouslySetInnerHTML={{ __html: post.html }}
          itemProp="articleBody"
        />
      </div>
    </Burrito>
  )
}

export default ExerciseTemplate

export const pageQuery = graphql`
  query ExerciseBySlug($id: String!) {
    site {
      siteMetadata {
        title
      }
    }
    markdownRemark(id: { eq: $id }) {
      id
      excerpt(pruneLength: 160)
      html
      fields {
        tagSlugs
      }
      frontmatter {
        title
        tags
      }
    }
  }
`
